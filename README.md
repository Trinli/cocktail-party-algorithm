# cocktail-party-algorithm
This is an implementation of independent component analysis (ICA) that solves the cocktail party problem. 
The algorithm falls under the larger class of unsupervised machine learning and is, in my opinion,
one of the more refined examples of it. The problem is also called "blind source separation" and is 
also found in magnetic resonance imaging (MRI). 

This is a project I made out of curiosity. 
The cocktail-party problem takes its name from the cocktail-party effect, which refers to the
setup you can run into on a cocktail-party: Even though there are lots of people talking at the
same time, people are still able to filter out the ones they are talking with. This indicates
that the brain has some mechanism to do this filtering, which in turn indicates that this could
potentially also be done mathematically. 
It turns out that it can be done. One solution to this problem is independent component
analysis (ICA). ICA assumes that you have more "recorders" (e.g. microphones in the room) than
there are "independent sources" (speakers in the room).

Assumptions
-data is in .wav format.

ICA works in a number of steps:
1. Center the data.
2. Whiten the data. This includes the following steps:
2.1. First we run an eigenvalue decomposition on the covariance matrix. This will give us an
orthogonal basis indicating the directions of highest variance. Assume that we have two sources,
then the complete mix of these sources will produce the highest variance. In a sense, you can
think of it as the original sources forming an 'X' and the direction of this highest variance
splitting that X in two.
2.2. Using these directions, we rotate the original data. Basically it can be seen as projecting
the data into this new space defined by the orthogonal basis found in 2.1. 
2.3. We now have the highest variance directions running along the principal axes in the coorinate
system. By dividing each variable with its corresponding variance, we will actually get unit
(co)variance in every direction. By now we have removed the first and second moments, i.e. the
mean and the variance. This process is simply called "whitening."
3. The central limit theorem roughly states that a combination of two random variables will be
more gaussian than either random variable alone. We utilize this property to find the original
signals using gradient descent:
3.1. We use kurtosis (a.k.a the fourth moment) as measure of non-gaussianity. We randomly pick
a vector with unit length as starting point.
3.2. We next estimate the gradient at this point, add the gradient times the learning rate to
the vector, and then project this vector onto a unit sphere (-> unit length vector). We
repeat this step until convergence.
3.3. When we have found one vector, we continue with the process in 3.2 but additionally requiring
that all new vectors be orthogonal to to the found ones.
4. We have now found the unit vectors corresponding to the original signals in the data. At this
point we simply project the data on all vectors separately bringing us the original signals.

Physics of the problem
The effect of sound on a distance from some source is roughly proportional to square of the
inverse distance, i.e. when the distance doubles from some source, the effect falls to 1/4.
As a consequence, when you have two microphones recording one source you usually measure different
effects in this, unless they happen to be at the exact same distance of the source. This version
of ICA assumes that the difference in these distances do not cause delays in the measurement, i.e.
that the microphones' distances to the source are reasonably small.
With this setup, if you plot a point where the x-coordinate is the effect of the sound as measured
by microphone 1 at some time, and the y-coordinate is the corresponding metric of microphone 2
at the same time, you will get a point that lies neither on the x-axis nor on the y-axis. If
you plot multiple points using the same logic, these will fall around an angled line where the
angle can be interpreted as a measure of the difference in distances of the two microphones.
If you have a second sound source playing at the same time, the corresponding points of this
would fall around a different line, except for that they also interact with with the measurements
from sound source 1. As a consequence, the two signals together will mostly fall around a third
line which is between the first two and captured by the highest variance direction estimated
in 2.1. These are then separated using the process described above. This description can also
be extended to cover more microphones and sound sources.

The sound files are originally from some researchers at Aalto University, if I remember correctly.
I could not find the source anymore.