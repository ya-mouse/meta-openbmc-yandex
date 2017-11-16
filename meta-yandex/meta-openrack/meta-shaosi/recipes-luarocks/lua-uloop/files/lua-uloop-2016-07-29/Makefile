LUA=/usr/lib/lua
LUAINC=$(LUA)/include
LUALIB=$(LUA)/lib
LUABIB=$(LUA)/bin

OFLAGS = -O3

I2C_CFLAGS = -I$(LUAINC) -std=gnu99 -DSTRUCT_INT="long long"
I2C_LDFLAGS = -L$(LUALIB) -lluajit-5.1
I2C_OBJ = lua-uloop.o uloop.o utils.o
I2C_LIB = uloop.so

all: $(I2C_LIB)

%.o: %.c
	$(CC) $(CPPFLAGS) $(CFLAGS) $(OFLAGS) $(LUA_CFLAGS) $(I2C_CFLAGS) $(FPIC) -c -o $@ $<

$(I2C_LIB): $(I2C_OBJ)
	$(CC) $(LDFLAGS) -shared -o $(I2C_LIB) $(I2C_OBJ) $(I2C_LDFLAGS)

install: $(I2C_LIB)

clean:
	rm -f *.o *.so
