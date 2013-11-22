#include <sstream>
using namespace std;

#include "m.h"

int main( int argc, char* argv[] )
{
	char experiment;
	int seed;
	double threshold;

	if( argc == 4 ) {
		experiment = argv[1][0];
		istringstream( argv[2] ) >> seed;
		istringstream( argv[3] ) >> threshold;

		SIM::funct( experiment, seed, threshold );
	}
	return 0;
}

