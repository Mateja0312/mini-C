// Korektan kod
//RETURN: 20
unsigned f(unsigned a){
	return a;
}

int f1(int a, int b){
	return a + b;
}

int func(int a, int b, int c){
	return a + b + c;
}

int main() {
	int a, b, c;
	a = 10;
	f(6u);
	c = f1(4, 3); // c = 7
	b = func(a, 3, c); // b = 10 + 3 + 7
    return b;
}
