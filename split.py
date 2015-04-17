
a = open('a.txt','r')
a = a.readlines()

core1 = open('core1.txt','w')
core2 = open('core2.txt','w')

l = len(a)

# lines = a.readlines()
c1 = []

'''
for i in range(len(lines)):
    if 'Core 1' in lines[i]:
	print lines[i]
        while lines[i] != '\n':
            c1.append(lines[i])
        c1.append('\n')

for line in c1:
    print line
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
