// ERROR: Narusena jednistvenost vrednosti slucajeva

int main() {
	int a, b, c, d;
	
	check (a){
		case 6 =>
			a = a + 1;
		case 2 => 
		{
			b = 3;
		}
		case 2 => d++;
	}
}
