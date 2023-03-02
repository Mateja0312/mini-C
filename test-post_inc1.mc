// Korektan kod
//RETURN: 21
int main() {
	int a, b, c, d;
	a = 2;
	b = 7;
	c = -1;
	
	a = a + b++ - c++; //2 + 7 + 1 = 10
	a = a + b++ + 3 - c; //10 + 8 + 3  - 0 = 21
	d++;
    return a;
}
