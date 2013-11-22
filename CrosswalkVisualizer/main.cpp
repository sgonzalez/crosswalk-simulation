
#include <SFML/Graphics.hpp>
#include <vector>

using namespace sf;
using namespace std;

#define DISTANCE_EDGE_MIDDLE 1155.0 // distance from where cars spawn to the middle of the crosswalk (i.e. 7*330/2)
#define DISTANCE_TO_CROSSWALK 165.0 // distance person has to walk to get to the crosswalk (i.e. 330/2)
#define BLOCK_WIDTH (330.0-24)
#define WIDTH_CROSSWALK 24.0
#define LENGTH_CROSSWALK 46.0

#define SCALING 0.5

RenderWindow window(VideoMode(DISTANCE_EDGE_MIDDLE*2*SCALING, LENGTH_CROSSWALK*14*SCALING), "Santiago and Matt's Crosswalk Visualizer");

void setup();
void render();
void update(Time delta);
void handleEvent(Event e);

RectangleShape background, road, topUIBox;
vector<RectangleShape> crosswalkLines;
vector<RectangleShape> residentialBlocks;

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
	
	topUIBox = RectangleShape(Vector2f(window.getSize().x-60, 60));
	topUIBox.setPosition(30, 0);
	topUIBox.setFillColor(Color(80, 80, 80, 164));
	
	for (int i = 0; i < 7; i++) {
		RectangleShape line = RectangleShape(Vector2f(WIDTH_CROSSWALK*SCALING, road.getSize().y/20));
		line.setPosition(window.getSize().x/2 - WIDTH_CROSSWALK*SCALING/2, road.getPosition().y + road.getSize().y/20 + i*road.getSize().y/7);
		crosswalkLines.push_back(line);
	}
	
	for (int i = 0; i < 7; i++) {
		RectangleShape b1 = RectangleShape(Vector2f(BLOCK_WIDTH*SCALING, BLOCK_WIDTH*SCALING));
		b1.setPosition(12*SCALING+i*(330)*SCALING, road.getPosition().y-12*SCALING-BLOCK_WIDTH*SCALING);
		b1.setFillColor(Color(0,200,0));
		RectangleShape b2 = RectangleShape(Vector2f(BLOCK_WIDTH*SCALING, BLOCK_WIDTH*SCALING));
		b2.setPosition(12*SCALING+i*(330)*SCALING, road.getPosition().y+LENGTH_CROSSWALK*SCALING+12*SCALING);
		b2.setFillColor(Color(0,200,0));
		crosswalkLines.push_back(b1);
		crosswalkLines.push_back(b2);
	}
}

void update(Time delta) {
	
}

void render() {
	window.draw(background);
	window.draw(road);
	for (std::vector<RectangleShape>::iterator it = crosswalkLines.begin(); it != crosswalkLines.end(); ++it) window.draw(*it);
	for (std::vector<RectangleShape>::iterator it = residentialBlocks.begin(); it != residentialBlocks.end(); ++it) window.draw(*it);
	window.draw(topUIBox);
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
