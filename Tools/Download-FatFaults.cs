// Synthetic durable FAT states supplement real QEMU power cuts. Fixture only.
using System;
using System.IO;
using System.Text;
using System.Collections.Generic;

public sealed class RecoveryDownloadFatFaults : IDisposable {
    sealed class Slot { public long At; public byte[] Raw; public Slot(long at, byte[] raw) { At=at; Raw=raw; } }
    sealed class Entry { public Slot Short; public List<Slot> Prefix; public string Name; }
    readonly FileStream file;
    readonly long start, fat, data;
    readonly int fatBytes;
    readonly int clusterBytes;
    readonly uint clusterCount;
    readonly uint root;
    RecoveryDownloadFatFaults(string image) {
        if (Path.GetExtension(image) != ".img") throw new IOException("Only a fixture .img is accepted.");
        file = new FileStream(image,FileMode.Open,FileAccess.ReadWrite,FileShare.None);
        try {
            if (file.Length != 2048L*1024*1024) throw new IOException("Unexpected fixture length.");
            var gpt=Read(512,512); if (Encoding.ASCII.GetString(gpt,0,8)!="EFI PART") throw new IOException("No fixture GPT.");
            var part=Read(1024+3*128,128);
            if (Encoding.Unicode.GetString(part,56,72).TrimEnd('\0')!="RECOVERY" || BitConverter.ToUInt64(part,32)!=2363392) throw new IOException("No expected RECOVERY partition.");
            start=(long)BitConverter.ToUInt64(part,32)*512;
            var bpb=Read(start,512);
            if (BitConverter.ToUInt16(bpb,11)!=512 || bpb[510]!=85 || bpb[511]!=170 || bpb[16]!=2) throw new IOException("Not fixture FAT32.");
            clusterBytes=bpb[13]*512; fat=start+BitConverter.ToUInt16(bpb,14)*512L;
            data=fat+bpb[16]*BitConverter.ToUInt32(bpb,36)*512L;
            fatBytes=checked((int)BitConverter.ToUInt32(bpb,36)*512);
            root=BitConverter.ToUInt32(bpb,44);
            clusterCount=(uint)((start+1048576L*512-data)/clusterBytes);
        } catch { file.Dispose(); throw; }
    }
    byte[] Read(long at,int count) { var b=new byte[count]; file.Position=at; file.ReadExactly(b); return b; }
    void Write(Slot slot) { file.Position=slot.At; file.Write(slot.Raw); file.Flush(true); }
    static uint Cluster(byte[] raw) { return ((uint)BitConverter.ToUInt16(raw,20)<<16)|BitConverter.ToUInt16(raw,26); }
    List<Slot> Slots(uint first) {
        var result=new List<Slot>(); var visited=new HashSet<uint>(); uint cluster=first;
        while (cluster<0x0ffffff8) {
            if (cluster<2 || cluster>=clusterCount+2 || !visited.Add(cluster) || result.Count>=4096) throw new IOException("Unexpected fixture directory chain.");
            long at=data+(cluster-2L)*clusterBytes;
            var bytes=Read(at,clusterBytes);
            for(int i=0;i<bytes.Length;i+=32) { var raw=new byte[32]; Array.Copy(bytes,i,raw,0,32); result.Add(new Slot(at+i,raw)); }
            cluster=BitConverter.ToUInt32(Read(fat+cluster*4L,4),0)&0x0fffffff;
        }
        return result;
    }
    static List<Entry> Entries(List<Slot> slots) {
        var result=new List<Entry>(); var prefix=new List<Slot>();
        foreach(var slot in slots) {
            var raw=slot.Raw; if(raw[0]==0) break;
            if(raw[0]==0xe5) { prefix.Clear(); continue; }
            if(raw[11]==15) { prefix.Add(slot); continue; }
            string name=Encoding.ASCII.GetString(raw,0,8).TrimEnd();
            string ext=Encoding.ASCII.GetString(raw,8,3).TrimEnd(); if(ext.Length!=0)name+="."+ext;
            if(prefix.Count!=0) {
                var chars=new List<char>();
                for(int i=prefix.Count-1;i>=0;i--) foreach(int off in new[]{1,3,5,7,9,14,16,18,20,22,24,28,30}) {
                    char ch=(char)BitConverter.ToUInt16(prefix[i].Raw,off); if(ch!=0 && ch!=0xffff)chars.Add(ch);
                }
                name=new string(chars.ToArray());
            }
            result.Add(new Entry { Short=slot, Prefix=new List<Slot>(prefix), Name=name }); prefix.Clear();
        }
        return result;
    }
    static Entry Find(List<Slot> slots,string name) {
        var hits=Entries(slots).FindAll(e=>e.Name.Equals(name,StringComparison.OrdinalIgnoreCase));
        if(hits.Count!=1)throw new IOException("Expected one fixture entry: "+name); return hits[0];
    }
    static Slot Free(List<Slot> slots) { var slot=slots.Find(s=>s.Raw[0]==0 || s.Raw[0]==0xe5); if(slot==null)throw new IOException("Fixture directory full."); return slot; }
    void Pad(List<Slot> slots,int until) {
        for(int i=0;i<until;i++) if(slots[i].Raw[0]==0) {
            slots[i].Raw=new byte[32]; Encoding.ASCII.GetBytes("PAD"+i.ToString("D5")+"TXT").CopyTo(slots[i].Raw,0);
            slots[i].Raw[11]=32; Write(slots[i]);
        }
    }
    void Apply(string mode) {
        var install=Find(Slots(root),"INSTALL"); var slots=Slots(Cluster(install.Short.Raw));
        if(mode=="orphan-create") {
            int index=slots.FindIndex(s=>s.Raw[0]==0 && s.At%512==480);
            if(index<0 || index+2>=slots.Count)throw new IOException("No sector boundary for orphan fixture.");
            Pad(slots,index);
            string name="INTERRUPTED_CREATION.PART";
            byte sum=0; foreach(byte b in Encoding.ASCII.GetBytes("ORPHAN~1PAR"))sum=(byte)(((sum&1)<<7)+(sum>>1)+b);
            for(int i=0;i<2;i++) {
                var raw=new byte[32]; int seq=2-i; raw[0]=(byte)(seq|(i==0?64:0)); raw[11]=15; raw[13]=sum;
                int j=(seq-1)*13;
                foreach(int off in new[]{1,3,5,7,9,14,16,18,20,22,24,28,30}) {
                    ushort ch=(ushort)(j<name.Length?name[j]:j==name.Length?0:0xffff); BitConverter.GetBytes(ch).CopyTo(raw,off); j++;
                }
                slots[index+i].Raw=raw; Write(slots[index+i]);
            }
            slots[index+2].Raw=new byte[32]; Write(slots[index+2]); return;
        }
        Find(slots,"RECOVERY.TXN"); var target=Find(slots,"RECOVERY.ZIP"); var stage=Find(slots,"RECOVERY.PART");
        if(stage.Prefix.Count!=1 || Cluster(stage.Short.Raw)==Cluster(target.Short.Raw))throw new IOException("Not the pre-publication fixture state.");
        if(mode=="lfn-detached") {
            // Put the one-slot PART prefix at the end of a sector and its
            // short owner at the next sector, as the real detach must support.
            int index=slots.FindIndex(s=>s.Raw[0]==0 && s.At%512==480);
            if(index<0 || index+1>=slots.Count)throw new IOException("No stage boundary.");
            var prefix=(byte[])stage.Prefix[0].Raw.Clone(); var shortRaw=(byte[])stage.Short.Raw.Clone();
            stage.Short.Raw[0]=0xe5;Write(stage.Short); stage.Prefix[0].Raw[0]=0xe5;Write(stage.Prefix[0]);
            Pad(slots,index);slots[index].Raw=prefix;Write(slots[index]);slots[index+1].Raw=shortRaw;Write(slots[index+1]);
            stage=new Entry { Short=slots[index+1],Prefix=new List<Slot>{slots[index]} };
        }
        var backup=Free(slots);backup.Raw=(byte[])target.Short.Raw.Clone();Encoding.ASCII.GetBytes("RECOVERYBAK").CopyTo(backup.Raw,0);Write(backup);
        if(mode=="alias-backup")return;
        if(mode!="alias-published" && mode!="lfn-detached")throw new IOException("Unknown fixture mode.");
        Array.Copy(stage.Short.Raw,20,target.Short.Raw,20,2);Array.Copy(stage.Short.Raw,26,target.Short.Raw,26,6);Write(target.Short);
        if(mode=="lfn-detached") { stage.Short.Raw[0]=0xe5;Write(stage.Short); }
    }
    public static void Patch(string image,string mode) { using(var fixture=new RecoveryDownloadFatFaults(image))fixture.Apply(mode); }
    uint[] Chain(uint first,byte[] table,HashSet<uint> owners) {
        var chain=new List<uint>(); uint cluster=first;
        while(cluster<0x0ffffff8) {
            if(cluster<2 || cluster>=clusterCount+2 || !owners.Add(cluster))throw new IOException("FAT fixture has a cross-link or invalid chain.");
            chain.Add(cluster);cluster=BitConverter.ToUInt32(table,checked((int)cluster*4))&0x0fffffff;
        }
        return chain.ToArray();
    }
    long Inspect() {
        var table=Read(fat,fatBytes);var mirror=Read(fat+fatBytes,fatBytes);
        if(!table.AsSpan().SequenceEqual(mirror))throw new IOException("FAT mirrors differ.");
        var owners=new HashSet<uint>();var directories=new Queue<uint>();directories.Enqueue(root);
        while(directories.Count!=0) {
            uint first=directories.Dequeue();Chain(first,table,owners);
            foreach(var entry in Entries(Slots(first))) {
                var raw=entry.Short.Raw;
                if(raw[0]=='.' || (raw[11]&8)!=0)continue;
                uint cluster=Cluster(raw);uint bytes=BitConverter.ToUInt32(raw,28);
                if((raw[11]&16)!=0) { directories.Enqueue(cluster);continue; }
                if(bytes==0 && cluster==0)continue;
                var chain=Chain(cluster,table,owners);
                if(chain.LongLength!=(bytes+(long)clusterBytes-1)/clusterBytes)throw new IOException("FAT chain length disagrees with file size.");
            }
        }
        long free=0;
        for(uint cluster=2;cluster<clusterCount+2;cluster++) {
            uint value=BitConverter.ToUInt32(table,checked((int)cluster*4))&0x0fffffff;
            if(value==0) { if(owners.Contains(cluster))throw new IOException("A live file owns a free cluster."); free++; }
            else if(!owners.Contains(cluster))throw new IOException("Unreachable allocated FAT cluster: "+cluster);
        }
        var info=Read(start+512,512);
        if(BitConverter.ToUInt32(info,488)!=free)throw new IOException("FAT free-cluster summary differs.");
        return free*clusterBytes;
    }
    public static long Check(string image) { using(var fixture=new RecoveryDownloadFatFaults(image))return fixture.Inspect(); }
    public void Dispose() { file.Dispose(); }
}
