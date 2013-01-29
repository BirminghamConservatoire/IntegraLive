

a = new("Flanger")
b = new("Delay")

i = new("AudioIn")
o = new("AudioOut")

-- connect
i.out1 = o.in1

wait(10)
print("hepp")
