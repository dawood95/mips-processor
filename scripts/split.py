file_in = open('a.txt','r')

lines = file_in.readlines()
c1 = []
c2 = []

for i in range(len(lines)):
    if 'Core 1' in lines[i]:
        print lines[i]
        while lines[i] != '\n':
            c1.append(lines[i])
            i += 1
        c1.append('\n')
    elif 'Core 2' in lines[i]:
        print lines[i]
        while lines[i] != '\n':
            c2.append(lines[i])
            i += 1
        c2.append('\n')

core1 = open('core1.txt','w')
core2 = open('core2.txt','w')

for line in c1:
    core1.write(line)

for line in c2:
    core2.write(line)


core1.close()


'''
for i in range(l):
    if (len(a[i]) > 14 and a[i][9:15] == 'Core 1'):
        core1.write(a[i]);
        i += 1;
        core1.write(a[i]);
        i += 1;
        core1.write(a[i]);
        i += 1;
        core1.write(a[i]);
    elif (len(a[i]) > 14 and a[i][9:15] == 'Core 2'):
        core2.write(a[i]);
        i += 1;
        core2.write(a[i]);
        i += 1;
        core2.write(a[i]);
        i += 1;
        core1.write(a[i]);
'''
