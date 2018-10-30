/*
  Copyright (C) 2011-2018 G. Bajlekov

    ImageFloat is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    ImageFloat is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

float negate(float a, float b) {
	return 1.0f - fabs(1.0f - a - b);
}

float exclude(float a, float b) {
	return a + b - 2.0f*a*b;
}

float screen(float a, float b) {
	return 1.0f - (1.0f-a)*(1.0f-b);
}

float overlay(float a, float b) {
	if (a<0.5f)
		return 2.0f*a*b;
	else
		return 1.0f - 2.0f*(1.0f - a)*(1.0f - b);
}

// http://www.pegtop.net/delphi/articles/blendmodes/hardlight.htm
float hardlight(float a, float b) {
	if (b<0.5f)
		return 2.0f*a*b;
	else
		return 1.0f - 2.0f*(1.0f - a)*(1.0f - b);
} // overlay with a and b swapped

// http://www.pegtop.net/delphi/articles/blendmodes/softlight.htm
float softlight(float a, float b) {
	return (1.0f - 2.0f*b)*pown(a, 2) + 2.0f*a*b;
}

// http://www.pegtop.net/delphi/articles/blendmodes/dodge.htm
float dodge(float a, float b) {
	return a/(1.0f - b + 0.0001f);
}

float softdodge(float a, float b) {
	if (a+b<1.0f)
		return 0.5f*a/(1.0f - b + 0.0001f);
	else
		return 1.0f - 0.5f*(1.0f - b)/(a + 0.0001f);
}

// http://www.pegtop.net/delphi/articles/blendmodes/burn.htm
float burn(float a, float b) {
	return 1.0f - (1.0f - a)/(b + 0.0001f);
}

float softburn(float a, float b) {
	if (a+b<1.0f)
		return 0.5f*b/(1.0f - a  + 0.0001f);
	else
		return 1.0f - 0.5f*(1.0f - a)/(b + 0.0001f);
}

// darktable
float linearlight(float a, float b) {
	return a + 2.0f*b - 1.0f;
}

// darktable
float vividlight(float a, float b) {
	if (b>0.5f)
		return a/(2.0f - 2.0f*b + 0.0001f);
	else
		return 1.0f - (1.0f - a)/(2.0f*b + 0.0001f);
}

// darktable
float pinlight(float a, float b) {
	if (b>0.5f)
		return fmax(a, 2.0f*b - 1.0f);
	else
		return fmin(a, 2.0f*b);
}
