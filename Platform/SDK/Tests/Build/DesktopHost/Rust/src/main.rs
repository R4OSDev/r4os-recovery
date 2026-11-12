#![no_std]
extern crate alloc;
use alloc::vec;
use core::pin::pin;
use r4os_sdk::{App,abi,bounded_text,gui::{Role,Session,SessionStorage,raw as c},path::FilePath,resources::Timeout,storage::System};
use r4os_r4img::{ApiV1Client,PngV1Client,RasterV1Client,R4ImgInfo};
use r4os_r4std::{SettingsV1Client,TimeV1Client,ConfigV1Client};
use r4os_r4gfx::{DeviceV1Client,ColorV1Client};
const BMP:&[u8]=include_bytes!("../../Shared/two-pixels.bmp");
fn checked(value:c::R4SdkGuiSlot)->bool{value.status==0 && value.flags & 2==0 && value.bits as i32>=0}
fn report(app:&App<'_>,bytes:&[u8])->bool{
 let Ok(sys)=System::new(app) else{return false};let Ok(path)=FilePath::parse(b"C:\\TEMP\\DH71R.TXT") else{return false};sys.files().write(&path,bytes).is_ok()
}
fn exercise(app:&App<'_>,host:&mut Session<'_, '_>)->Result<(),i32>{
 let _settings=SettingsV1Client::init(app).map_err(|_|10)?;let _time=TimeV1Client::init(app).map_err(|_|10)?;let _config=ConfigV1Client::init(app).map_err(|_|10)?;
 let images=ApiV1Client::init(app).map_err(|_|10)?;let _png=PngV1Client::init(app).map_err(|_|10)?;let _raster=RasterV1Client::init(app).map_err(|_|10)?;
 let _devices=DeviceV1Client::init(app).map_err(|_|10)?;let _colors=ColorV1Client::init(app).map_err(|_|10)?;
 let mut allocation=vec![0u8;24576];for(i,v)in allocation.iter_mut().enumerate(){*v=(i as u8).wrapping_mul(17).wrapping_add(3);}
 if allocation.iter().enumerate().any(|(i,v)|*v!=(i as u8).wrapping_mul(17).wrapping_add(3)){return Err(13);}drop(allocation);
 let mut label=[0u8;64];let utf8="SDK71 Rust A\u{301} 🙂".as_bytes();if !bounded_text::valid(utf8) || !bounded_text::assign_z(&mut label,utf8){return Err(15);}
 let mut info=R4ImgInfo::default();let mut scratch_bytes=0;let mut count=0;let mut pixels=[0u32;2];let mut scaled=[0u32;64];
 unsafe{
  if images.probe(BMP.as_ptr(),BMP.len() as u64,b"image/bmp".as_ptr(),9,&mut info)!=0 || info.width!=2 || info.height!=1 || images.scratch_bytes(&info,BMP.len() as u64,&mut scratch_bytes)!=0 || scratch_bytes>16*1024*1024{return Err(16);}
  let mut scratch=vec![0u8;scratch_bytes as usize];
  if images.decode(BMP.as_ptr(),BMP.len() as u64,b"image/bmp".as_ptr(),9,pixels.as_mut_ptr(),2,scratch.as_mut_ptr(),scratch_bytes,&mut info,&mut count)!=0 || count!=2 || pixels[0]&0xffffff!=0xff0000 || pixels[1]&0xffffff!=0x00ff00{return Err(19);}drop(scratch);
  if images.scale_composite(&info,pixels.as_ptr(),2,scaled.as_mut_ptr(),64,8,8,0,&mut count)!=0 || count!=64{return Err(20);}
  let draw=host.native_draw();
  if !checked(c::R4SdkGuiDrawContext_displayBeginFrameRect(0,draw,0,0,240,64)){return Err(21);}
  if !checked(c::R4SdkGuiDrawContext_rect(0,draw,0,0,240,64,0x24384c)) || !checked(c::R4SdkGuiDrawContext_text(0,draw,8,8,label.as_ptr(),0xffffff,0x24384c)) || !checked(c::R4SdkGuiDrawContext_displayBlitXrgb32(0,draw,8,32,8,8,scaled.as_ptr(),64)) || !checked(c::R4SdkGuiDrawContext_displayPresent(0,draw)){return Err(22);}
  let mut mouse=core::mem::MaybeUninit::<abi::Mouse>::uninit();if !checked(c::R4SdkGuiDesktopContext_mouseState(0,host.native_desktop(),mouse.as_mut_ptr())){return Err(23);}
 }
 if !report(app,b"READY Rust claim/imports/allocator/image/text/raster\r\n"){return Err(24);}
 for _ in 0..120000{
  let key=unsafe{c::R4SdkGuiDesktopContext_readKeyCodepoint(0,host.native_desktop())};if key.status!=0{return Err(25);}if key.bits==u64::from(b'q'){return Ok(());}app.sleep(1);
 }
 Err(26)
}
fn probe(app:&App<'_>)->Result<(),i32>{
 let mut storage=pin!(SessionStorage::new());let mut timers=[];
 let mut host=Session::open(storage.as_mut(),app,Role::DesktopHost,&mut timers).map_err(|_|1)?;
 let claim=host.claim_host(Timeout::AfterNanos(2_000_000_000)).map_err(|_|2)?;
 if claim.desktop_owner.instance_id as u64!=app.instance_id() || claim.desktop_epoch==0{return Err(3);}
 let result=exercise(app,&mut host);drop(host);result
}
fn main(app:&mut App<'_>)->i32{
 let code=probe(app).err().unwrap_or(0);let mut result=*b"R71 result=000 close=done\r\n";result[11]=b'0'+(code/100) as u8;result[12]=b'0'+((code/10)%10) as u8;result[13]=b'0'+(code%10) as u8;
 if !report(app,&result){return 99;}code
}
r4os_sdk::app!(main);
