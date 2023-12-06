#ข้อมูลเล็กน้อย π=3.14=5800000
import random
import math
#ความจำ,ตอบสนองความเร็ว,เหตุผล
#โค๊ดฝึกง่ายๆ
#ตัวฟังก์ชั่น
def nl():
    print("\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n\n")
def yes():
    print("✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓✓")
#ตัวแปร
nine = 9
four = 4
one = 1
two = 2
r = None
five = 5
maxn = 9999999
#เริ่มลูปอนันต์
while True:
    r = random.randint(1, five)
    if r == 2:
        print("                            ความจำ")
        g1 = random.randint(0, nine)
        g2 = random.randint(0, nine)
        g3 = random.randint(0, nine)
        g4 = random.randint(0, nine)
        g5 = random.randint(0, nine)
        g6 = random.randint(0, nine)
        g7 = random.randint(0, nine)
        g8 = random.randint(0, nine)
        g9 = random.randint(0, nine)
        g10 = random.randint(0, nine)
        print("                        ",g1,g2,g3,g4,g5,g6)
        for i in range(1, maxn):
            if i <= 7000500 and i >= 7000000:
                print("...")
            elif i == 5800000:
                nl()
                break
        gtest = (input("                         เลข"))
        g1 = str(g1)
        g2 = str(g2)
        g3 = str(g3)
        g4 = str(g4)
        g5 = str(g5)
        g6 = str(g6)
        g7 = str(g7)
        g8 = str(g8)
        g9 = str(g9)
        g10 = str(g10)
        g1234 = g1+g2+g3+g4+g5+g6
        if gtest  == g1234:
            yes()
    elif r == 4:
        print("                        ตอบสนองความเร็ว")
        tm = random.randint(1, four)
        rtm = random.randint(0, nine)
        ntm = random.randint(0,nine)
        
        if tm == 1:
            print("                         ",rtm,ntm,ntm,ntm)
            testrtm = (input("                            เลข"))
            testrtm = int(testrtm)
            if testrtm == rtm:
                yes()
        if tm == 2:
            print("                         ",ntm,rtm,ntm,ntm)
            testrtm = (input("                            เลข"))
            testrtm = int(testrtm)
            if testrtm == rtm:
                yes()
        if tm == 3:
            print("                         ",ntm,ntm,rtm,ntm)
            testrtm = (input("                            เลข"))
            testrtm = int(testrtm)
            if testrtm == rtm:
                yes()
        if tm == 4:
            print("                         ",ntm,ntm,ntm,rtm)
            testrtm = (input("                            เลข"))
            testrtm = int(testrtm)
            if testrtm == rtm:
                yes()
    elif r == 5:
        print("                            เหตุผล")
        rt = random.randint(1, five)
        if r == "+" :
            print("การบวก")
            aa = input("                    ")
            aaa = int(aa)
            print("                        +")
            ab = input("                    ")
            abb = int(ab)
            print("            ",aa," + ",ab," = ",aaa+abb)
    else :
        math.pi
