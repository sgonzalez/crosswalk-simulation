#include <SFML/Graphics.hpp>

int main()
{
    sf::RenderWindow window(sf::VideoMode(200, 200), "SFML works!");
    sf::CircleShape shape(100.f);
    shape.setFillColor(sf::Color::Green);

    while (window.isOpen())
    {
        sf::Event event;
        while (window.pollEvent(event))
        {
            if (event.type == sf::Event::Closed)
                window.close();
        }

        window.clear();
        window.draw(shape);
        window.display();
    }

    return 0;
}


/*#include <sstream>
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

*/