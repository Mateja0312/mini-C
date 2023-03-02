// ERROR: zamenjena mesta ':' i '?'
int main()
{
	int a, b;
	a = 3;
	b = 2;
	a = a + (a == b) : a ? b + 3;
	return a;
}
