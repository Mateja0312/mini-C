// ERROR: b nije deklarisano
//RETURN: 8
int main()
{
	int a;
	a = 3;
	a = a + (a == b) ? a : b + 3; //3 + 2 + 3
	return a;
}
