// ERROR: vrednosti prosledjene funkciji se ne poklapaju sa trazenim vrednostima

int func(int a, int b, void c){
	return 3;
}

int main() {
	int a, b;
	unsigned c;
	func(a, b, c);
    return 0;
}
