//OPIS: inkrement u numexp-u
//RETURN: 54

int y;

int main() {
    int x;
    x = 2;
    y = 6;
    y = x++ + y++ + 42;
    return x + y;
}

