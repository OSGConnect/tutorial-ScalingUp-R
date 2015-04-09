montecarloPi <- function(trials) {
  count = 0
  for(i in 1:trials) {
    if((runif(1,0,1)^2 + runif(1,0,1)^2)<1) {
      count = count + 1
    }
  }
  return((count*4)/trials)
}
 
montecarloPi(1000)
