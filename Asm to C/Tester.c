#define CHECK_FORMAT __attribute__ ((format (printf, 1, 2)))
//typedef void (CDECL *int)(int);

void Printf (const char* format, ...) CHECK_FORMAT;

#undef CHECK_FORMAT

int main()
{
    Printf ("azaz %x %c%c\a \t%s \n xx %d %o azaz инфа 100%%\n", 3802, 'x', 'x', "Ахаха", 128, 64);
    int x = 228;
    Printf ("Проверяем: %d", x);
    return 0;
}
