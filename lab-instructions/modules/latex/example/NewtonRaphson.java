class NewtonRaphson {
	private static double f(double x) {
		return ...;
	}
	
	private static double fprim(double x) {
		return ...;
	}
	
	public static double solve(double x0, double eps) {
		double x1 = x0;
		do {
			x0 = x1;
			x1 = x0 - f(x0) / fprim(x0);
		} while (Math.abs(x1 - x0) > Math.abs(x1) * eps);
		return x1;
	}
}
