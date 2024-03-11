import random
x = 10
a = 0
b = 0
c = 0
inp = 0
xx = 9999999999
aa = "0"
bb = "0"
cc = "0"
for i in range(1, xx):
    a = random.randint(0, x)
    b = random.randint(0, x)
    print("                        ",a,"+",b,"=")
    c = (a+b)
    try:
        inp = input("                         คำตอบ :")
    except NameError:
        print("กรุณาพิมพ์ตัวเลข")
    except :
        pass
    aa = str(a)
    bb = str(b)
    cc = str(c)
    if inp == cc:
        print("yes")
    if inp != cc:
        print("game over")
        break
