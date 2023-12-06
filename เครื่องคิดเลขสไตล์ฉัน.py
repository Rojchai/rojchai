#ตัวแปร
a = ("1") #+
b = ("2") #-
c = ("3") #*
d = ("4") #/
e = ("5") # %
f = ("6") # **
g = ("7") #//
stop = ("stop") #no
inf = 99999999999999999999999999999
#หน้าหลัก
print("                            ระบบคำนวน")
print("                     พิมพ์ตัวเลขตามด้านล่าง")
print("                 1=+ "+"2=- "+"3=× "+"4=÷ "+"5=% "+"6=** "+"7=//")
for r in range(1, inf):
    r = input("ระบุ")
    #ifหัวข้อย่อย
    if r == a :
        print("การบวก")
        aa = input("                    ")
        aaa = int(aa)
        print("                        +")
        ab = input("                    ")
        abb = int(ab)
        print("            ",aa," + ",ab," = ",aaa+abb)
    if r == b :
        print("การลบ")
        ba = input("                    ")
        baa = int(ba)
        print("                        -")
        bb = input("                    ")
        bbb = int(bb)
        print("            ",ba," - ",bb," = ",baa-bbb)
    if r == c :
        print("การคูณ")
        ca = input("                    ")
        caa = int(ca)
        print("                        ×")
        cb = input("                    ")
        cbb = int(cb)
        print("            ",ca," × ",cb," = ",caa*cbb)
    if r == d :
        print("การหาร")
        da = input("                    ")
        daa = int(da)
        print("                        ÷")
        db = input("                    ")
        dbb = int(db)
        print("            ",da," ÷ ",db," = ",daa/dbb)
    if r == e :
        print("การหารเอาเศษ")
        ea = input("                    ")
        eaa = int(ea)
        print("                        %")
        eb = input("                    ")
        ebb = int(eb)
        print("            ",ea," % ",eb," = ",eaa%ebb)
    if r == f :
        print("การยกกำลัง")
        fa = input("                    ")
        faa = int(fa)
        print("                        **")
        fb = input("                    ")
        fbb = int(fb)
        print("            ",fa," ** ",fb," = ",faa**fbb)
    if r == g :
        print("การหารปัดเศษทิ้ง")
        ga = input("                    ")
        gaa = int(ga)
        print("                        //")
        gb = input("                    ")
        gbb = int(gb)
        print("            ",ga," // ",gb," = ",gaa//gbb)

    if r == stop :
        print("จบ")
        break
