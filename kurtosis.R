cocktailParty <- function(input, mu=0.001, convergence=1e-10){ ## Could also be called simply ICA...
	## No assumptions on # of independent components or input dims =)
	## mu is step-size for gradient descent
	## This only finds one local optimum. In a 2-d case, the other one is 
	## perpendicular to the found one...
	## With random restarts, we could find multiple such optima. 
	## The starting points would not even have to be random, one in every
	## quadrant should do (as long as they don't hit a zero point).
	white_data <- whiten(input)
	## Gradient descent for ICA
	## 1. Start with random vector w or length 1:
	w <- matrix(rnorm(dim(input)[2]), nrow=dim(input)[2], ncol=1) 
	w <- w/as.numeric(sqrt(t(w)%*%w))
	kurt_tmp_1 <- kurtosis(white_data%*%w)
	kurt_tmp_2 <- -1e15
	## Loop tests for convergence:
	while(kurt_tmp_1-kurt_tmp_2 > convergence){
#	for( i in 1:1000){
		## 2. Estimate gradient for w^t*x and take small step in direction of it
		## gradient = 4*sign(kurtosis(z*w))*(E(z*(w^t*z)^3) -3w||w||^2 )
		grad <- sign(kurtosis(white_data %*% w))*(1/dim(input)[1]*t(z)%*%(z%*%w)^3
			- 3*w) ## The -3*w can be dropped as it is aligned with w
			## and will only decrease the magnitude of the projection of the 
			## first part on the sphere ||w||=1.
		## Could also replace the next with a fixed point iteration and 
		## not care about step size. Supposedly converges faster. Works
		## because w is a sphere and w_new is always projected back to
		## the unit sphere.
		w <- w + mu*grad 
		## 4. Normalize w to |w| = 1 (unit length!)
		## Apparently sqrt(.) requires an explicit conversion for division to work..
		w <- w / as.numeric(sqrt(t(w)%*%w))
		## 5. Test convergence
		kurt_tmp_2 <- kurt_tmp_1 ## Does kurtosis flip sign between iterations? nope.
		kurt_tmp_1 <- kurtosis(white_data %*% w)
		## 6. Repeat 2-5 until convergence
	}
	return(w)
	## We could repeat the process for a number of random starting points w
	## until we find dim(input)[2] different w's that converge
}
