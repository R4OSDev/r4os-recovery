use r4os_sdk::{
    abi, bounded_text as text,
    directory_page::OrderedPage,
    path::{AbsoluteFilePath, FilePath, RegistryPath, RelativeFilePath},
    registry_hive as hive,
};
unsafe extern "C" {
    fn SDKStorageCodecC() -> u64;
}
pub fn codecs() {
    assert_eq!(
        FilePath::parse(b"c:/TEMP/./ONE/../FILE.TXT")
            .unwrap()
            .as_bytes(),
        b"C:\\TEMP\\FILE.TXT"
    );
    assert!(AbsoluteFilePath::parse(b"../FILE").is_err());
    assert!(RelativeFilePath::parse(b"C:\\FILE").is_err());
    assert!(FilePath::parse(b"C:\\..\\FILE").is_err());
    assert!(FilePath::parse(b"C:\\BAD\0FILE").is_err());
    assert!(FilePath::parse("C:\\ä€\\FILE.TXT".as_bytes()).is_ok());
    assert!(FilePath::parse("C:\\🙂.TXT".as_bytes()).is_ok());
    assert!(FilePath::parse(b"C:\\\xf4\x90\x80\x80.TXT").is_err());
    assert!(FilePath::parse(b"C:\\BAD*.TXT").is_err());
    assert!(FilePath::parse(b"C:\\\xc3").is_err());
    assert_eq!(
        RegistryPath::parse(b"HKCU/Software/Test")
            .unwrap()
            .as_bytes(),
        b"HKCU\\Software\\Test"
    );
    let value = "ä€🙂a\u{301}.txt".as_bytes();
    let mut out = [0xa5; 32];
    for cap in 0..=out.len() {
        out.fill(0xa5);
        let before = out;
        let ok = text::assign_z(&mut out[..cap], value);
        assert_eq!(ok, cap > value.len());
        if !ok {
            assert_eq!(out, before)
        }
        assert_eq!(&out[cap..], &before[cap..]);
    }
    assert!(!text::valid(b"a\0b"));
    assert!(!text::valid(b"\xc1\xa1"));
    assert!(text::label_z(&mut out[..9], value));
    let n = out[..9].iter().position(|&b| b == 0).unwrap();
    assert!(core::str::from_utf8(&out[..n]).is_ok());
    assert_eq!(text::load_prefix("xa\u{301}z".as_bytes(), 2, true), Some(1));
    let count = 42u32.to_le_bytes();
    let values = [
        hive::BuildValue::new(
            b"SYSTEM\\Config",
            b"Count",
            abi::registry_value_type_u32,
            &count,
        ),
        hive::BuildValue::new(
            b"SYSTEM\\Config",
            b"Enabled",
            abi::registry_value_type_bool,
            &[1],
        ),
    ];
    let mut scratch = [0; 64 * 1024];
    let mut bytes = [0; 4096];
    let built = hive::build(1, 0x1122334455667788, &values, &mut scratch, &mut bytes).unwrap();
    let hash = built.iter().fold(0xcbf29ce484222325u64, |h, &b| {
        (h ^ u64::from(b)).wrapping_mul(0x100000001b3)
    });
    assert_ne!(hash, 0);
    assert_eq!(hash, unsafe { SDKStorageCodecC() });
    assert_eq!(
        u64::from_le_bytes(built[24..32].try_into().unwrap()),
        0x1122334455667788,
        "binary generation"
    );
    let parsed = hive::Hive::parse(built).unwrap();
    assert_eq!(parsed.header().generation, 0x1122334455667788);
    assert_eq!(
        parsed
            .get(b"SYSTEM\\Config", b"Count")
            .unwrap()
            .unwrap()
            .as_u32(),
        Some(42)
    );
    assert_eq!(
        parsed
            .get(b"SYSTEM\\Config", b"Enabled")
            .unwrap()
            .unwrap()
            .as_bool(),
        Some(true)
    );
    assert!(parsed.get(b"SYSTEM\\Config", b"Absent").unwrap().is_none());
    assert!(parsed.key(u32::MAX).unwrap().is_none());
    let mut exported = [0; 4096];
    let exported = hive::export_text(&parsed, &mut scratch, &mut exported).unwrap();
    let mut second = [0; 4096];
    let second = hive::import_text(exported, 4, &mut scratch, &mut second).unwrap();
    assert_eq!(
        hive::Hive::parse(second)
            .unwrap()
            .get(b"SYSTEM\\Config", b"Count")
            .unwrap()
            .unwrap()
            .as_u32(),
        Some(42)
    );
    let mut small = [0; 8];
    assert!(
        matches!(hive::build(1,0x1122334455667788,&values,&mut scratch,&mut small),Err(hive::Error::OutputCapacity{required}) if required>8)
    );
    assert!(hive::build(1, 0x1122334455667788, &values, &mut [], &mut small).is_err());
    let mut page = OrderedPage::<u32, 3>::new().unwrap();
    for v in [9, 3, 7, 1, 8] {
        page.offer(v, |a, b| a < b);
    }
    assert!(page.iter().copied().eq([1, 3, 7]));
}
