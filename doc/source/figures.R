require(ggplot2)
theme_set(theme_minimal())
setwd("C:\\Users\\Galin\\Dropbox\\ImageFloat3\\doc\\source\\nodes")

Input = seq(0, 1, len=1024)

brightness = function(i, b) {
  b = b + 1
  o = (1-b)*i^2 + b*i
  return(o)
}

d1 = data.frame(x = Input, y = brightness(Input, 1), b = "+1.0")
d2 = data.frame(x = Input, y = brightness(Input, 0.5), b = "+0.5")
d3 = data.frame(x = Input, y = brightness(Input, 0), b = "+0.0")
d4 = data.frame(x = Input, y = brightness(Input, -0.5), b = "-0.5")
d5 = data.frame(x = Input, y = brightness(Input, -1), b = "-1.0")

data = rbind(d1, d2, d3, d4, d5)
data$b = factor(data$b)
p = qplot(data = data, x = x, y = y, color = b, geom="line", group = b, size = I(1)) +
  scale_color_brewer(palette = "Dark2", guide = guide_legend(label.position = "top")) +
  xlab("Input") + ylab("Output") + ggtitle("Brightness Curve") +
  theme(legend.position="top") +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(legend.title=element_blank()) + theme(legend.key.width = unit(1.5,"cm"))
  

plot(p)
ggsave("brightness/plot.png", p, width = 4, height = 4, units="in", dpi=120, bg="transparent")


contrast = function(i, c) {
  c = c + 1
  i = 2*i - 1
  o = ifelse(i<0, (c-1)*i^2 + i*c, (1-c)*i^2 + i*c)
  o = (o+1)/2
  return(o)
}

d1 = data.frame(x = Input, y = contrast(Input, 1), b = "+1.0")
d2 = data.frame(x = Input, y = contrast(Input, 0.5), b = "+0.5")
d3 = data.frame(x = Input, y = contrast(Input, 0), b = "+0.0")
d4 = data.frame(x = Input, y = contrast(Input, -0.5), b = "-0.5")
d5 = data.frame(x = Input, y = contrast(Input, -1), b = "-1.0")

data = rbind(d1, d2, d3, d4, d5)
data$b = factor(data$b)
p = qplot(data = data, x = x, y = y, color = b, geom="line", group = b, size = I(1)) +
  scale_color_brewer(palette = "Dark2", guide = guide_legend(label.position = "top")) +
  xlab("Input") + ylab("Output") + ggtitle("Contrast Curve") +
  theme(legend.position="top") +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(legend.title=element_blank()) + theme(legend.key.width = unit(1.5,"cm"))
  
plot(p)
ggsave("contrast/plot.png", p, width = 4, height = 4, units="in", dpi=120, bg="transparent")




parametric1 = function(i, b) {
  o = b*i*(2*i-1)^2
  o[i>0.5] = 0
  return(o)
}

parametric2 = function(i, b) {
  o = b*(i-1)^2*i
  return(o)
}

parametric3 = function(i, b) {
  o = -b*(i-1)*i^2
  return(o)
}

parametric4 = function(i, b) {
  o = -b*(i-1)*(2*i-1)^2
  o[i<0.5] = 0
  return(o)
}

library(manipulate)
manipulate(
  {
    O1 = Input + parametric2(Input, p2/100) + parametric3(Input, p3/100)
    O2 = O1 + parametric1(Input, p1/100)*O1/Input + parametric4(Input, p4/100)*(1-O1)/(1-Input)
    plot(Input, O2, "l")
  },
  p1=slider(-100,100),
  p2=slider(-100,100),
  p3=slider(-100,100),
  p4=slider(-100,100))

d1 = data.frame(x = Input, y = parametric1(Input, 1), b = "+1.0", p="Shadows")
d2 = data.frame(x = Input, y = parametric1(Input, -1), b = "-1.0", p="Shadows")
d3 = data.frame(x = Input, y = parametric2(Input, 1), b = "+1.0", p="Darks")
d4 = data.frame(x = Input, y = parametric2(Input, -1), b = "-1.0", p="Darks")
d5 = data.frame(x = Input, y = parametric3(Input, 1), b = "+1.0", p="Lights")
d6 = data.frame(x = Input, y = parametric3(Input, -1), b = "-1.0", p="Lights")
d7 = data.frame(x = Input, y = parametric4(Input, 1), b = "+1.0", p="Highlights")
d8 = data.frame(x = Input, y = parametric4(Input, -1), b = "-1.0", p="Highlights")

d9 = data.frame(x = Input, y = d3$y + d5$y, b = "+1.0", p="Darks + Lights")
d10 = data.frame(x = Input, y = d4$y + d6$y, b = "-1.0", p="Darks + Lights")



data = rbind(d1, d3, d5, d7)
data$b = factor(data$b)
p = qplot(data = data, x = x, y = y, color = p, geom="line", group = interaction(b, p), size = I(1)) +
  scale_color_brewer(palette = "Dark2", guide = guide_legend(label.position = "top")) +
  xlab("Input") + ylab("F (V = +1.0)") + ggtitle("Parametric Curves") +
  theme(legend.position="top") +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(legend.title=element_blank()) + theme(legend.key.width = unit(1.5,"cm"))

plot(p)
ggsave("parametric/plot.png", p, width = 4, height = 3, units="in", dpi=120, bg="transparent")

data = rbind(d1, d2, d3, d4, d9, d10, d5, d6, d7, d8)
data$b = factor(data$b)
p = qplot(data = data, x = x, y = y + Input, color = p, geom="line", group = interaction(b, p), size = I(1)) +
  scale_color_brewer(palette = "Dark2", guide = guide_legend(label.position = "top")) +
  xlab("Input") + ylab("Output") + ggtitle("Parametric Curves") +
  theme(legend.position="top") +
  theme(plot.title = element_text(hjust = 0.5)) +
  theme(legend.title=element_blank()) + theme(legend.key.width = unit(1.5,"cm"))

plot(p)
#ggsave("parametric/plot2.png", p, width = 4, height = 4, units="in", dpi=120, bg="transparent")
