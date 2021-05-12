# MiniC
MiniC is a toy compiler that generates MIPS assembly code for a tiny subset of the C programming language. The compiler is made using Flex and Bison.

## How to Build MiniC?

1. ``` $make clean ```
2. ``` $make do ```

## How to Execute?
3. ``` $./a.out<Tests/fib.prog ```. Other sample tests can be found at ./Tests/
4. To check the MIPS code generated in the file "mips.asm" assemble and run it on MARS simulator using command \
``` java -jar ./Mars4_5.jar ```

## Features Implemented
* Datatype supported: int.
* Loops: while, for (nested as well)
* Conditionals: if else (nested as well)
* Booleans
* Input from user
* Print 
* Function calls: parameter passing, return(except in main)
* Airthmetic Operators: +, -, /, *, %, Negation
* Relational Operators: ==, <=, >=,!=, <, >
* Logical Operators: &&, ||
* Handling comments
* Error Reporting
* Recursion
* One-dimensional Array

## Group Members
* [Mihir Jain](https://github.com/mihirjain-iitgn)
* [Janvi Thakkar](https://github.com/jvt3112)
* [Aishna Agrawal](https://github.com/Aishnaagrawal)
* [Priyam Tongia](https://github.com/Priyam1418)

## References
* [Lab Problems](https://canvas.instructure.com/courses/2496326/files/folder/Labs)
* http://web.eecs.utk.edu/~bvanderz/teaching/cs461Sp11/notes/bison/
* https://github.com/oyzh/tiger/tree/master/chap2
