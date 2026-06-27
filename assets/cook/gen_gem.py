#!/usr/bin/env python3
# Compose the game's td_* cook textures from the Gemini pixel sprites in gem/.
# All assembly-bowl layers share the opening anchor at display (64,50) = tex (256,200),
# so the existing draw math in Main.gd stays unchanged. ART_SS=4 (tex = 4x display).
import numpy as np
from PIL import Image, ImageDraw
import os
HERE=os.path.dirname(__file__); GEM=os.path.join(HERE,"gem")
def L(n): return Image.open(os.path.join(GEM,n)).convert("RGBA")
def save(im,n): im.save(os.path.join(HERE,n)); print("wrote",n,im.size)

ANCHOR=(256,200)          # opening centre in the 512 texture (=display 64,50)
RX,RY=200,150             # interior radii in tex space (display 50,38 *4 ~)

def canvas(): return Image.new("RGBA",(512,512),(0,0,0,0))

def ellipse_mask(rx,ry,cx=ANCHOR[0],cy=ANCHOR[1]):
    m=Image.new("L",(512,512),0); d=ImageDraw.Draw(m)
    d.ellipse((cx-rx,cy-ry,cx+rx,cy+ry),fill=255)
    return m

def place(sprite, scale, src_pt, dst=ANCHOR):
    w,h=sprite.size
    s=sprite.resize((max(1,int(w*scale)),max(1,int(h*scale))),Image.NEAREST)
    sx,sy=int(src_pt[0]*scale),int(src_pt[1]*scale)
    c=canvas(); c.alpha_composite(s,(dst[0]-sx,dst[1]-sy)); return c

# --- 1) assembly bowl base (bowl.png) -------------------------------
# bowl.png cream interior bbox (7,22)-(230,112) center (118,67), width 223
bowl=L("bowl.png")
SB=2*RX/223.0                                   # interior width 223 -> 400
td_bowl=place(bowl, SB, (118,67))
save(td_bowl,"td_bowl.png")

# helper: crop the food interior of a source bowl (inset from alpha bbox) and
# return it scaled+masked to an interior ellipse at the anchor.
def food_layer(name, inset_l,inset_t,inset_r,inset_b, rx,ry, dy=0):
    im=L(name); a=np.asarray(im); ys,xs=np.where(a[...,3]>40)
    x0,y0,x1,y1=xs.min(),ys.min(),xs.max(),ys.max()
    cx0=x0+int((x1-x0)*inset_l); cx1=x1-int((x1-x0)*inset_r)
    cy0=y0+int((y1-y0)*inset_t); cy1=y1-int((y1-y0)*inset_b)
    crop=im.crop((cx0,cy0,cx1,cy1)).resize((2*rx,2*ry),Image.NEAREST)
    layer=canvas(); layer.alpha_composite(crop,(ANCHOR[0]-rx,ANCHOR[1]-ry+dy))
    m=ellipse_mask(rx,ry,cy=ANCHOR[1]+dy)
    la=np.asarray(layer).copy(); mm=np.asarray(m)
    la[...,3]=np.minimum(la[...,3],mm)
    return Image.fromarray(la,"RGBA")

# --- 2) broth / noodles / beef layers (aligned to bowl interior) ----
save(food_layer("soup.png",    0.16,0.22,0.16,0.30, 196,82, dy=-4), "td_broth.png")
save(food_layer("noodles.png", 0.18,0.20,0.18,0.34, 176,70, dy=-6), "td_noodles.png")
save(food_layer("beef.png",    0.20,0.16,0.20,0.40, 150,58, dy=-14),"td_beef.png")

# --- 3) topping boxes: fit each bowl into 192x192 (display 48) ------
def fit(name, box):
    im=L(name); a=np.asarray(im); ys,xs=np.where(a[...,3]>40)
    crop=im.crop((xs.min(),ys.min(),xs.max()+1,ys.max()+1))
    s=min(box/crop.width, box/crop.height)
    cw,ch=int(crop.width*s),int(crop.height*s)
    crop=crop.resize((cw,ch),Image.NEAREST)
    c=Image.new("RGBA",(box,box),(0,0,0,0)); c.alpha_composite(crop,((box-cw)//2,(box-ch)//2))
    return c
for nm,key in [("beef","td_box_beef"),("scallion","td_box_scallion"),
               ("cilantro","td_box_cilantro"),("chili","td_box_chili")]:
    save(fit(f"{nm}.png",192), f"{key}.png")

# --- 4) soup/noodle pot mouths: fit into 464x200 (display 116x50) ---
# show the upper part of the bowl (the liquid/noodle surface) in the mouth
def potmouth(name):
    im=L(name); a=np.asarray(im); ys,xs=np.where(a[...,3]>40)
    crop=im.crop((xs.min(),ys.min(),xs.max()+1,ys.max()+1))
    s=464.0/crop.width
    cw,ch=464,int(crop.height*s)
    crop=crop.resize((cw,ch),Image.NEAREST)
    c=Image.new("RGBA",(464,200),(0,0,0,0))
    c.alpha_composite(crop,(0, 200-ch+10))           # bottom-align; mouth at top
    return c
save(potmouth("soup.png"),    "td_bowl_soup.png")
save(potmouth("noodles.png"), "td_bowl_noodle.png")
print("DONE")
