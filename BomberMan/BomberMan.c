// First I need to write in C and then MIPS assembly, so C code should be simple as possible

#include <stdio.h>
#include <stdlib.h>

char grid[200*200];
int r, c, n;

// isDigit function returns 1 if the character is a digit, 0 otherwise
int isDigit(char c)
{
    if(c >= '0' && c <= '9')
        return 1;
    return 0;
}

void fillWithBombs()
{
    for(int i = 0; i < r; i++)
    {
        for(int j = 0; j < c; j++)
        {
            if(grid[i*c+j] == '.') // if empty cell
                grid[i*c+j] = '3'; // 3 seconds to explode
        }
    }
}

void timePasses()
{
    n--; // 1 second passed
    for(int i = 0; i < r; i++)
    {
        for(int j = 0; j < c; j++)
        {   
            if(isDigit(grid[i*c+j]) == 1) // if it is a digit
                grid[i*c+j]--; // decrease the time 
        }
    }
}

// explode function makes bombs explode and inactivates the naeighbor bombs if there is one 
void explode()
{
    for(int i = 0; i < r; i++)
    {
        for(int j = 0; j < c-1; j++)
        {
            if(grid[i*c+j] == '0') // if it is a bomb about to explode
            {
                grid[i*c+j] = '.'; // explode the bomb and inactivate the neighbor bombs : 
                if(i>0 && grid[(i-1)*c+j] != '0') // if it is not the first row and the cell above is not a bomb about to explode
                {
                    grid[(i-1)*c+j] = '.'; // inactivate the bomb above if there is one or it will continue to be a empty cell 
                }
                if(i<r-1 && grid[(i+1)*c+j] != '0') // if it is not the last row and the cell below is not a bomb about to explode
                {
                    grid[(i+1)*c+j] = '.'; // inactivate the bomb below if there is one or it will continue to be a empty cell
                }
                if(j>0 && grid[i*c+j-1] != '0') // if it is not the first column and the cell to the left is not a bomb about to explode
                {
                    grid[i*c+j-1] = '.'; // inactivate the bomb to the left if there is one or it will continue to be a empty cell
                }
                if(j<c-2 && grid[i*c+j+1] != '0') // if it is not the last column and the cell to the right is not a bomb about to explode
                {
                    grid[i*c+j+1] = '.'; // inactivate the bomb to the right if there is one or it will continue to be a empty cell
                }
            }
        }
    }
}

void initializeFirstBombs()
{
    for(int i = 0; i < r; i++)
    {
        for(int j = 0; j < c; j++)
        {   
            if(grid[i*c+j] == 'O') // if it is a bomb
                grid[i*c+j] = '3'; // 3 seconds to explode
        }
    }
}

void takeInputs()
{
    printf("Enter the row and column numbers: ");
    scanf("%d %d", &r, &c);
    printf("Enter the time..: ");
    scanf("%d", &n);
    c++; // +1 for \n
    printf("Enter the grid: \n");
    getchar(); // to get rid of \n
    for(int i = 0; i < r; i++) //+1 for \n
    {
        for(int j = 0; j < c; j++)
        {
            scanf("%c", &grid[i*c+j]);
        }
    }
    printf("\n");
}

//print the grid
void printGrid()
{
    for(int i = 0; i < r; i++)
    {
        for(int j = 0; j < c ; j++)
        {
            if(isDigit(grid[i*c+j]) == 1) // if it is a digit that means it is a bomb, integer represents the time to explode the bomb
                printf("O");
            else if(grid[i*c+j] == '.') // if it is a dot that means it is an empty cell
                printf(".");
            else 
                printf("%c", grid[i*c+j]); // if it is not a digit or a dot, it is \n or \0 so print it
        }
    }
    printf("\n");
}

//main program
int main()
{
    takeInputs(); // take the grid infos (rows, columns and grid itself)

    initializeFirstBombs(); // initialize the first bombs because user dont know how grid will be used in the program 
    timePasses();

    // Loop until the time is up
    while(n > 0) //time passes, bombs explode and bombs are planted until the time is up 
    {
        timePasses();
        explode(); // bombs explode if there is one to explode in this second
        if(n == 0) break; // if it is the last second break the loop


        fillWithBombs(); // fill empty cells with bombs

        timePasses(); // time passes
        explode(); // bombs explode if there is one to explode in this second
        if(n == 0) break; // if it is the last second break the loop
    }
    printGrid(); // print the final grid
}
