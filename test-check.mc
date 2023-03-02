// Korektan kod
//RETURN: 15

int main() {
	int a, b, c, d;
	
	a = 3;
	b = 2;
	c = 8;
	d = 100;
	
	check (a){
		case 1 =>
			a = a + 5;
		case 2 => 
		{
			b = 3;
		}
		otherwise => c++;
	}
	
	b = 6;
	
	check (c){
		case  6 => b = 200;
		case  7 => b = 200;
		case  8 => b = 200;
		case 10 => b = 200;
		case 11 => b = 200;
	}
	
	check (b){
		case 6 =>
			d = c + 5;
		case 1 => 
		{
			b = 3;
		}
		case 2 => d++;
	}
	
	d++;
	
	return d;
}
