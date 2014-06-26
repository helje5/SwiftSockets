//
//  UnixBridge.h
//  ARISockets
//
//  Created by Helge Heß on 6/26/14.
//
//

// I think the originals are not mapped because they are using varargs
extern int ari_fcntlVi (int fildes, int cmd, int val);
extern int ari_ioctlVip(int fildes, unsigned long request, int *val);
