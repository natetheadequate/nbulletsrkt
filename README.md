# N-Bullets in Racket
For a Fundies 2 assignment, we were tasked with making a knockoff of [this game](https://www.crazygames.com/game/10-bullets-html-5) in Java. Over Spring Break, I rewrote it in Racket, which was the language Fundies 1 was taught in *Update Fall 2023: Northeastern has switched from Racket to Kotlin Script. This makes me sad (not that I have anything against Kotlin, I just like how Racket forces everybody to think differently about programming, rather than giving a leg up to people with experience)*. Doing the same project in both languages revealed key differences between them

## Java required more code
Racket was tested more extensively and included templates, yet it had only 597 lines, 2993 words, and 25750 characters compared to 1198 lines, 4398 words, and 47446 characters across all 8 java files. 

## This isn't an entirely fair comparison
I wrote the Racket program in Intermediate Student Language with Lambdas, which was the final version of the language we were able to use in the class. Without the use of lambdas, the program would have been a lot longer and clunkier. Fundies 2 featured a similar progression However, at the point when we made N-Bullets in java, we were restricted in what featured had been "unlocked" for us to use. This was made difficult because we were not able to mutate the world, so whenever a single attribute of the world was changed, parameters that didn't change had to be passed to the constructor as well. We partially overcame this by creating a SettingsBundle object to store things that would be constant throughout a particular game (the speeds of projectiles, time limit, Random seed, etc) so we could consolidate all of those into a single parameter. With the ability to use static fields, this is no longer an issue, but we had not yet been permitted to use that capability. 
There was only one real mechanism to do this in Racket, which was to declare these game constants at the start of the file, which I don't think is significantly worse or better than making a static field in java.

## Testing
Using the tester library in Java required a separate class and methods, which felt less elegant than the Racket style of having the tests immediately before the function body. 

## Abstraction
In the Java version, we ended up making an abstract class which our Bullet and Ship classes inherited. In the Racket version, I had made a union datatype in a similar fashion, but then found that it was not actually necessary. Since Racket has functions not methods, I could reuse the same collision method with explicit types for its parameters as the first being a ship and the second being bullet. This would not have been possible in java, where one would be fixed as `this` and the other being the parameter.  

## Abstraction and Testing
Although I do like Test-Driven development, it can be somewhat obstructive if at some point, a function is deemed unnecessary, or should be broken up further, but there has been a large amount of time put into writing tests. 

## Testing and Helper Functions
It appears to me that the best way to test functions with helpers without going overboard is to have the main function just test that the helper is invoked when it should be, and returns a reasonable result. The edge cases for each helper should be tested there. However, it is not necessarily optimal to actually invoke the helper in the test because there is the possibility that the helper doesn't do what you think it does -- tests in the main function serve as a good sanity check that all the helper functions are working in concordance properly.

## Randomness
Although I eventually changed it, there was a point where the function to generate a random number of ships had a dummy parameter which was necessary to prevent the function from being memoized. After following the design recipe closer, I rewrote the function to call a helper function with a random number as a parameter, which then generated that number of ships in a random place. 

## More On Randomness
Using Random objects in java was a source of much pain, especially when it came to testing, since new constructors had to be made which took in a Random seed. Because of tests, the Random seed had to be lugged along every time a game was made like the blanket of Linus from Peanuts. Having to alter the actual code for the sake of tests doesn't seem very clean. Furthermore, without mutability, a new Random seed had to be made at the start of every test method which had any randomness since the order in which the tester lib runs the test methods is random and changes each time. 
On the other hand, check-random worked lovely in Racket 
