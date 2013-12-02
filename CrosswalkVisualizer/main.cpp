
#include <SFML/Graphics.hpp>
#include "ResourcesHelper.h"
#include <iostream>
#include <vector>
#include <string>
#include <fstream>
#include <sstream>

using namespace sf;
using namespace std;

#define DISTANCE_EDGE_MIDDLE 1155.0 // distance from where cars spawn to the middle of the crosswalk (i.e. 7*330/2)
#define DISTANCE_TO_CROSSWALK 165.0 // distance person has to walk to get to the crosswalk (i.e. 330/2)
#define BLOCK_WIDTH (330.0-24)
#define WIDTH_CROSSWALK 24.0
#define LENGTH_CROSSWALK 46.0

#define SCALING 0.5

float updateInterval = 0.001; // update every updateInterval seconds

enum StoplightColor {
	StoplightRed,
	StoplightYellow,
	StoplightGreen
	};

RenderWindow window(VideoMode(DISTANCE_EDGE_MIDDLE*2*SCALING, LENGTH_CROSSWALK*14*SCALING), "Santiago and Matt's Crosswalk Visualizer");
Font font;

// Trace file
string tracefile;
string currentline;
stringstream tracestream;
std::vector<std::string> &split(const std::string &s, char delim, std::vector<std::string> &elems);

// Game loop
void setup();
void render();
void update(Time delta);
void handleEvent(Event e);

// Visualization state
void resetVis();
void updateStoplightColor(StoplightColor newcolor);
vector<float> carsLeftBound;
vector<float> carsRightBound;
vector<float> pedestrianPositions;
StoplightColor currentColor = StoplightGreen;
unsigned int currentTrace;
float accumulatedTimeSinceLastUpdate;

// UI elements
RectangleShape background, road, topUIBox, stoplightRect, walkRect;
CircleShape cRed, cYellow, cGreen;
Text titleLabel, infoLabel, timeLabel, walkLabel, carCountLabel, pedCountLabel, speedLabel, speedLabelLabel;
vector<RectangleShape> crosswalkLines;
vector<RectangleShape> residentialBlocks;


int main(int argc, const char *argv[]) {
	// Load trace file
	string tracefilename = "../Crosswalk/trace.dat";
	if (argc == 2) {
		tracefilename = string(argv[1]);
	}
	cout << "Reading trace from: " << tracefilename << endl;
	ifstream t(tracefilename);
	stringstream buffer;
	buffer << t.rdbuf();
	tracefile = buffer.str();
	tracestream << tracefile;
	
	// Setup
	Clock clock;
	accumulatedTimeSinceLastUpdate = 0;
	if (!font.loadFromFile(resourcePath() + "HelveticaNeue.ttf")) return EXIT_FAILURE;
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
		accumulatedTimeSinceLastUpdate += delta.asSeconds();
		if (accumulatedTimeSinceLastUpdate > updateInterval) {
			accumulatedTimeSinceLastUpdate = 0;
			update(delta);
		}
		
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
	
	stoplightRect = RectangleShape(Vector2f(130, 40));
	stoplightRect.setPosition(window.getSize().x/2-65, 10);
	stoplightRect.setFillColor(Color(0, 0, 0, 64));
	
	walkRect = RectangleShape(Vector2f(70, 40));
	walkRect.setPosition(window.getSize().x/2+65+30, 10);
	walkRect.setFillColor(Color(0, 0, 0, 64));
	walkLabel = Text("walk", font, 25);
	walkLabel.setPosition(walkRect.getPosition().x+10, 15);
	
	cRed = CircleShape(15);
	cRed.setPosition(stoplightRect.getPosition().x+5, 15);
	cYellow = CircleShape(15);
	cYellow.setPosition(stoplightRect.getPosition().x+50, 15);
	cGreen = CircleShape(15);
	cGreen.setPosition(stoplightRect.getPosition().x+95, 15);
	updateStoplightColor(StoplightGreen);
	
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
	
	titleLabel = Text("Crosswalk Visualizer", font, 30);
	titleLabel.setPosition(45, 5);
    titleLabel.setColor(sf::Color::Black);
	
	infoLabel = Text("Press 'R' to reset visualization", font, 15);
	infoLabel.setPosition(45, 40);
    infoLabel.setColor(Color::Black);
	
	timeLabel = Text("0 s", font, 25);
	timeLabel.setPosition(window.getSize().x-150, 15);
	timeLabel.setColor(Color::Black);
	
	pedCountLabel = Text("0 pedestrians", font, 15);
	pedCountLabel.setPosition(window.getSize().x-300, 10);
	pedCountLabel.setColor(Color::Black);
	
	carCountLabel = Text("0 automobiles", font, 15);
	carCountLabel.setPosition(window.getSize().x-300, 30);
	carCountLabel.setColor(Color::Black);
	
	speedLabel = Text("100", font, 20);
	speedLabel.setPosition(370, 25);
	speedLabel.setColor(Color::Black);
	
	speedLabelLabel = Text("Vis Speed ^/v", font, 15);
	speedLabelLabel.setPosition(370, 10);
	speedLabelLabel.setColor(Color::Black);
	
	speedLabel.setString(to_string((int)(1.0/updateInterval)));
	
	resetVis();
}

void update(Time delta) {
	carsLeftBound.clear();
	carsRightBound.clear();
	currentTrace ++;
	
	// Get next line from trace file
	string newcurrentline;
	if (!tracestream.eof()) getline(tracestream, newcurrentline);
	if (newcurrentline.size() > 0) currentline = newcurrentline;
	
	// Split line on colons
	vector<string> vect;
    split(currentline, ':', vect);
	
	// Split car positions
	vector<string> carPositionsLeft, carPositionsRight;
	split(vect[3], ',', carPositionsLeft);
	split(vect[4], ',', carPositionsRight);
	// Convert car positions from strings to floats
	carsLeftBound.clear();
	carsRightBound.clear();
	std::transform(carPositionsLeft.begin(), carPositionsLeft.end(), std::back_inserter(carsLeftBound), [](const std::string& str) { return std::stof(str); });
	std::transform(carPositionsRight.begin(), carPositionsRight.end(), std::back_inserter(carsRightBound), [](const std::string& str) { return std::stof(str); });
	
	// Split pedestrian positions
	vector<string> pedPositions;
	split(vect[5], ',', pedPositions);
	pedestrianPositions.clear();
	std::transform(pedPositions.begin(), pedPositions.end(), std::back_inserter(pedestrianPositions), [](const std::string& str) { return std::stof(str); });
	
	// Update relevant variables
	currentTrace = stoi(vect[0]);
	timeLabel.setString(vect[1]+" s");
	carCountLabel.setString(to_string(carsLeftBound.size()+carsRightBound.size())+" automobiles");
	pedCountLabel.setString(to_string(pedestrianPositions.size())+" pedestrians");
	if (vect[2] == "GREEN")
		updateStoplightColor(StoplightGreen);
	else if (vect[2] == "YELLOW")
		updateStoplightColor(StoplightYellow);
	else
		updateStoplightColor(StoplightRed);
}

void render() {
	window.draw(background);
	window.draw(road);
	for (std::vector<RectangleShape>::iterator it = crosswalkLines.begin(); it != crosswalkLines.end(); ++it) window.draw(*it);
	for (std::vector<RectangleShape>::iterator it = residentialBlocks.begin(); it != residentialBlocks.end(); ++it) window.draw(*it);
	window.draw(topUIBox);
	window.draw(stoplightRect);
	window.draw(walkRect);
	window.draw(walkLabel);
	window.draw(cRed);
	window.draw(cYellow);
	window.draw(cGreen);
	window.draw(titleLabel);
	window.draw(infoLabel);
	window.draw(timeLabel);
	window.draw(carCountLabel);
	window.draw(pedCountLabel);
	window.draw(speedLabel);
	window.draw(speedLabelLabel);
	
	// draw leftbound cars
	for (std::vector<float>::iterator it = carsLeftBound.begin(); it != carsLeftBound.end(); ++it) {
		float position = *it;
		CircleShape cCar(4);
		cCar.setOrigin(2, 2);
		cCar.setPosition(road.getSize().x-position*SCALING, road.getPosition().y+road.getSize().y*1.0/5.0);
		cCar.setFillColor(Color::Magenta);
		window.draw(cCar);
	}
	
	// draw rightbound cars
	for (std::vector<float>::iterator it = carsRightBound.begin(); it != carsRightBound.end(); ++it) {
		float position = *it;
		CircleShape cCar(4);
		cCar.setOrigin(2, 2);
		cCar.setPosition(position*SCALING, road.getPosition().y+road.getSize().y*3.0/5.0);
		cCar.setFillColor(Color::Cyan);
		window.draw(cCar);
	}
	
	// draw pedestrians
	for (std::vector<float>::iterator it = pedestrianPositions.begin(); it != pedestrianPositions.end(); ++it) {
		float position = *it;
		CircleShape cPed(4);
		cPed.setOrigin(2, 2);
		cPed.setPosition(window.getSize().x/2, road.getPosition().y-DISTANCE_TO_CROSSWALK*SCALING+position*SCALING);
		cPed.setFillColor(Color::Blue);
		window.draw(cPed);
	}
}

void handleEvent(Event e) {
	if (e.type == Event::KeyPressed) {
		if (e.key.code == Keyboard::R) {
			resetVis();
		} else if (e.key.code == Keyboard::Up) {
			updateInterval -= 0.005;
			updateInterval = (updateInterval < 0) ? 0.005: updateInterval;
			speedLabel.setString(to_string((int)(1.0/updateInterval)));
		} else if (e.key.code == Keyboard::Down) {
			updateInterval += 0.005;
			speedLabel.setString(to_string((int)(1.0/updateInterval)));
		}
	}
}



#pragma mark - Trace file stuff

void resetVis() {
	std::cout << "\nResetting Visualization...";
	
	// set cursor position to beginning of stringstream
	tracestream.clear();
	tracestream.seekg(0, ios::beg);
}

void updateStoplightColor(StoplightColor newcolor) {
	currentColor = newcolor;
	
	switch (currentColor) {
		case StoplightGreen:
			cRed.setFillColor(Color(100,0,0));
			cYellow.setFillColor(Color(100,100,0));
			cGreen.setFillColor(Color::Green);
			walkLabel.setColor(Color(100,0,0));
			break;
		case StoplightYellow:
			cRed.setFillColor(Color(100,0,0));
			cYellow.setFillColor(Color::Yellow);
			cGreen.setFillColor(Color(0,100,0));
			walkLabel.setColor(Color(100,0,0));
			break;
		case StoplightRed:
			cRed.setFillColor(Color::Red);
			cYellow.setFillColor(Color(100,100,0));
			cGreen.setFillColor(Color(0,100,0));
			walkLabel.setColor(Color::White);
			break;
	}
}

std::vector<std::string> &split(const std::string &s, char delim, std::vector<std::string> &elems) {
    std::istringstream ss(s);
    std::string item;
    while (std::getline(ss, item, delim)) {
        elems.push_back(item);
    }
    return elems;
}

