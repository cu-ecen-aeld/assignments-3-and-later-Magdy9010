#Compiler
CC = $(CROSS_COMPILE)gcc

#Compiler Flags
CFLAGS = -Wall -Wextra -std=c11

#Target
TARGET = writer

#Source
SRCS = writer.c

#Object files
OBJS = writer.o

#Build all
all: $(TARGET)

$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(SRCS)

#Compile C to OBJ
%.o: %.c
	$(CC) $(CFLAGS) -c $< -o $@

# Clean up
clean:
	rm -f $(OBJS) $(TARGET)
