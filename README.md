# cocktail-party-algorithm
Implementation of independent component analysis (ICA) that solves the cocktail party problem.

This is a project I made out of curiosity. 
The cocktail-party problem takes its name from the cocktail-party effect, which refers to the
setup you can run into on a cocktail-party: Even though there are lots of people talking at the
same time, people are still able to filter out the ones they are talking with. This indicates
that the brain has some mechanism to do this filtering, which in turn indicates that this could
potentially also be done mathematically. 
It turns out that it can be done. One solution to this problem is independent component
analysis (ICA). ICA assumes that you have more "recorders" (e.g. microphones in the room) than
there are speakers (independent sources).

Assumptions
-data is in .wav format.

ICA works in a number of steps:
1. The data is centered.
2. The data is whitened. This includes the following steps:
2.1 First we run an eigenvalue decomposition on the covariance matrix. This will give us an
orthogonal basis indicating the directions of highest variance. Assume that we have two sources,
then the complete mix of these sources will produce the highest variance. In a sense, you can
think of it as the original sources forming an 'X' and the direction of this highest variance
splitting that X in two.
2.2 Using these directions, we rotate the original data. Basically it can be seen as projecting
the data into this new space defined by the orthogonal basis found in 2.1. 
2.3 We now have the highest variance directions running along the principal axes in the coorinate
system. By dividing each variable with its corresponding variance, we will actually get unit
(co)variance in every direction. By now we have removed the first and second moments, i.e. the
mean and the variance. This process is simply called "whitening."
3. The central limit theorem roughly states that a combination of two random variables will be
more gaussian than either random variable alone. We utilize this property to find the original
signals using numerical gradient descent:
3.1 We use kurtosis (a.k.a the fourth moment) as measure of non-gaussianity. We estimate kurtosis
of our data on some unit vector (randomly initialized).
3.2 We further estimate the kurtosis for a unit vector that is "close" to the first one in the sense
that the angle between this unit vector and the unit vector in 3.1 is small. If the kurtosis for
the unit vector in 3.2 is better than in 3.1, we use this vector as the new baseline and continue
until we converge.
4. We have now found the unit vectors corresponding to the original signals in the data. At this
point we simply project the data on both vectors separately bringing us the original signals.
