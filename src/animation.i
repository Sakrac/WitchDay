struct AnimPlayData {
	word DataStart
	byte Frame ; current frame
	byte Wait ; frames left until next frame
	byte Index ; sprite index
}

struct AnimData {
	word Graphics
	byte Height
	byte Width
	byte Frames
}

struct AnimFrameData {
	byte Index
	byte Duration
}

