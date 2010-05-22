// By GreaseMonkey.
// Public domain.
// Needs minecraft.jar or minecraft-server.jar or a suitable Level class replacement.

import java.io.*;
import java.util.zip.*;
import com.mojang.minecraft.level.Level;

public class NotchToMCTA
{
	public static int map_get_rle(byte bytes[], int offs)
	{
		int t = bytes[offs];
		if (offs == bytes.length)
			return 1;
	
		for(int i = offs+1; i < bytes.length; i++)
		{
			if(bytes[i] != t)
				return i-offs;
			if((i-offs) > 0x7F)
				return 0x7F;
		}
		
		if(bytes.length-offs > 0x7F)
			return 0x7F;
		
		return bytes.length-offs;
	}

	public static int map_get_lz(byte bytes[], int offs, int btrk)
	{
		for(int i = offs; i < bytes.length; i++)
		{
			if(bytes[i] != bytes[i-btrk])
				return i-offs;
			if((i-offs) > 0x7F)
				return 0x7F;
		}
		
		if(bytes.length-offs > 0x7F)
			return 0x7F;
		
		return bytes.length-offs;
	}
	
	public static void pack32(byte b[], int o, int v)
	{
		b[o++] = (byte)(v>>24);
		b[o++] = (byte)(v>>16);
		b[o++] = (byte)(v>>8);
		b[o++] = (byte)v;
	}
	
	public static void main(String args[]) throws Exception
	{
		InputStream fp = new FileInputStream(new File(args[0]));
		byte b[] = new byte[5];
		fp.read(b,0,5);
		if(b[0] == 0x1F && b[1] == (byte)0x8B && b[2] == 0x08)
		{
			fp.close();
			fp = new GZIPInputStream(new FileInputStream(new File(args[0])));
			fp.read(b,0,5);
		}
		ObjectInputStream fp2 = new ObjectInputStream(fp);
		Level lv = (Level)fp2.readObject();

		int xSpawn = lv.xSpawn;
		int ySpawn = lv.ySpawn;
		int zSpawn = lv.zSpawn;
		int xLen = lv.width;
		int yLen = lv.depth;
		int zLen = lv.height;
		System.out.printf("spawn = %d %d %d\n",xSpawn,ySpawn,zSpawn);
		System.out.printf("size  = %d %d %d\n",xLen,yLen,zLen);
		
		OutputStream ofp = new FileOutputStream(new File(args[1]));
		
		b = new byte[4*7];
		b[0] = 'M'; b[1] = 'C'; b[2] = 'T'; b[3] = 'A';
		pack32(b,4,xLen);
		pack32(b,8,yLen);
		pack32(b,12,zLen);
		pack32(b,16,xSpawn);
		pack32(b,20,ySpawn);
		pack32(b,24,zSpawn);
		ofp.write(b,0,b.length);
		
		int offs = 0;
		byte bytes[] = lv.blocks;
		while(offs < bytes.length)
		{
			int sel = 1;
			int l = map_get_rle(bytes,offs);
	
			if(offs >= xLen)
			{
				int al = map_get_lz(bytes,offs,xLen);
				if(al > l)
				{
					l = al;
					sel = 2;
				}
			}
	
			if(offs >= xLen*zLen)
			{
				int al = map_get_lz(bytes,offs,xLen*zLen);
				if(al > l)
				{
					l = al;
					sel = 3;
				}
			}
			
			if(l == 1)
				ofp.write(bytes, offs, 1);
			else if(sel == 1) {
				if(l > 0xFF)
					l = 0xFF;
				ofp.write(new byte[] { (byte)(bytes[offs]+0x80), (byte)(l) }, 0, 2);
			} else if(sel == 2) {
				if(l > 0x7F)
					l = 0x7F;
				ofp.write(new byte[] { (byte)0xFF, (byte)(l) }, 0, 2);
			} else if(sel == 3) {
				if(l > 0x7F)
					l = 0x7F;
				ofp.write(new byte[] { (byte)0xFF, (byte)(l+0x80) }, 0, 2);
			}
			//System.out.printf("%d %d\n", offs, l);
			offs += l;
		}
		
		ofp.close();
	}
}

