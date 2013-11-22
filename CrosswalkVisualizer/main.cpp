
#include <SFML/Graphics.hpp>

using namespace sf;
using namespace std;

#define DISTANCE_EDGE_MIDDLE 1155 // distance from where cars spawn to the middle of the crosswalk (i.e. 7*330/2)
#define DISTANCE_TO_CROSSWALK 165 // distance person has to walk to get to the crosswalk (i.e. 330/2)
#define WIDTH_CROSSWALK 24
#define LENGTH_CROSSWALK 46

#define SCALING 3

RenderWindow window(VideoMode(DISTANCE_TO_CROSSWALK*2*SCALING, LENGTH_CROSSWALK*2*SCALING), "Santiago and Matt's Crosswalk Visualizer");

void setup();
void render();
void update(Time delta);
void handleEvent(Event e);

RectangleShape background, road;

int main() {
	Clock clock;
	setup();
	
	// Start the game loop
    while (window.isOpen()) {
		Time delta = clock.restart();
        // Process events
        sf::Event event;
        while (window.pollEvent(event))
        {
            // Close window : exit
            if (event.type == sf::Event::Closed) {
                window.close();
            }
			
            // Espace pressed : exit
            if (event.type == sf::Event::KeyPressed && event.key.code == sf::Keyboard::Escape) {
                window.close();
            }
			
			handleEvent(event);
        }
		
        // Clear screen
        window.clear();
		
		// Update the stuff
		update(delta);
		
		// Draw the stuff
		render();
		
        // Update the window
        window.display();
    }
	
    return 0;
}

void setup() {
	background = RectangleShape(Vector2f(window.getSize().x, window.getSize().y));
    background.setFillColor(Color::Green);
	
	road = RectangleShape(Vector2f(window.getSize().x, SCALING*LENGTH_CROSSWALK));
	road.setPosition(0, window.getSize().y/2-SCALING*LENGTH_CROSSWALK/2);
    road.setFillColor(Color::Black);
}

void update(Time delta) {
	
}

void render() {
	window.draw(background);
	window.draw(road);
}

void handleEvent(Event e) {
	
}


// Here is a small helper for you ! Have a look.
//#include "ResourcePath.hpp"

/*int main(int, char const**)
{
    // Create the main window
    sf::RenderWindow window(sf::VideoMode(800, 600), "SFML window");

    // Set the Icon
    sf::Image icon;
    if (!icon.loadFromFile(resourcePath() + "icon.png")) {
        return EXIT_FAILURE;
    }
    window.setIcon(icon.getSize().x, icon.getSize().y, icon.getPixelsPtr());

    // Load a sprite to display
    sf::Texture texture;
    if (!texture.loadFromFile(resourcePath() + "cute_image.jpg")) {
        return EXIT_FAILURE;
    }
    sf::Sprite sprite(texture);

    // Create a graphical text to display
    sf::Font font;
    if (!font.loadFromFile(resourcePath() + "sansation.ttf")) {
        return EXIT_FAILURE;
    }
    sf::Text text("Hello SFML", font, 50);
    text.setColor(sf::Color::Black);

    // Load a music to play
    sf::Music music;
    if (!music.openFromFile(resourcePath() + "nice_music.ogg")) {
        return EXIT_FAILURE;
    }

    // Play the music
    music.play();

    // Start the game loop
    while (window.isOpen())
    {
        // Process events
        sf::Event event;
        while (window.pollEvent(event))
        {
            // Close window : exit
            if (event.type == sf::Event::Closed) {
                window.close();
            }

            // Espace pressed : exit
            if (event.type == sf::Event::KeyPressed && event.key.code == sf::Keyboard::Escape) {
                window.close();
            }
        }

        // Clear screen
        window.clear();

        // Draw the sprite
        window.draw(sprite);

        // Draw the string
        window.draw(text);

        // Update the window
        window.display();
    }
    
    return EXIT_SUCCESS;
}*/
