// "test-sanity2.mc"
int fun(){int a;return a;}

void vfun(int b, unsigned a, unsigned c)
{
	unsigned v;
	v = a + c;
}

int main()
{
	//%
	/* dad a
		ö ш
	ćšđ 😀
	🙂
	
	d a*/

	int a, f;
	int b, c, d, e, g;
	int promenljiva;
	unsigned u;
	int i;
	
	u=5u;
	
	vfun(3, 3, 3);
	
	g=0;
	a = a - 2;
	a=a+b++-c;
	a=a+b+++-3; // a = a + b++ + -3
	a=a+b++-+3; // a = a + b++ - +3
	a=8;
	
	if(f==0)
	{
		f = a + 3;
	}
	
	if(a>3 and b<5 and c==4)
	{
		a++;
	}
	else
	{
		a=b + c + d - g;
	}
	
	
	for int i in ( 6 .. 27 step 3 )
		for int j in ( 6 .. 27 step 3 ) {g++; a = 3 + b - c;}
		
	for int i in ( 6 .. 27 step 3 )
		u=6u;
	//komentar
	
	
	
	check (a){
		case 1 =>
			a = a + 5;
			
		case 2 => 
		{
			b = 3;
		}
	}
	
	check (a){
		case 6 =>
			a = a + 1;
		case 1 => 
		{
			b = 3;
		}
		case 2 => g++;
		
		otherwise => c++;
	}
	return 0;
}
