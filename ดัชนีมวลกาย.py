a = 18.5
b = 24.9
c = 29.9
d = 30
kk = float(input("ระบุน้ำหนัก :"))
m = float(input("ระบุส่วนสูงเมตร.เซนติเมตร :"))
m = (m**2)
R = (kk/m)
print("ดัชนีมวลกายคือ",R)
if R < a :
    print("ผอม")
elif R > a and R < b :
    print("สมส่วน")
elif R > b and R < c :
    print("อ้วน")
else :
    print("อ้วนมาก")
