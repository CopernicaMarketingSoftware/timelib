FLAGS=-O2 \
	-Wall -Werror -Wextra \
	-Wmaybe-uninitialized -Wmissing-field-initializers -Wshadow -Wno-unused-parameter \
	-pedantic -Wno-implicit-fallthrough \
	-DHAVE_STDINT_H -DHAVE_GETTIMEOFDAY -DHAVE_UNISTD_H -DHAVE_DIRENT_H -I.#

CFLAGS=-Wdeclaration-after-statement -fPIC ${FLAGS}

CPPFLAGS=${FLAGS}

LDFLAGS=-lm

TEST_LDFLAGS=-lCppUTest

VERSION=18.1
SHARED=libtimelib.so.${VERSION}
STATIC=libtimelib.a.${VERSION}

CC=gcc
CXX=g++
OBJECTS=parse_iso_intervals.o parse_date.o unixtime2tm.o tm2unixtime.o \
	dow.o parse_tz.o parse_zoneinfo.o timelib.o astro.o interval.o
MANUAL_TESTS=tests/tester-parse-interval \
	tests/tester-parse-tz tests/tester-iso-week tests/test-abbr-to-id \
	tests/enumerate-timezones tests/date_from_isodate
AUTO_TESTS=tests/tester-parse-string tests/tester-parse-string-by-format \
	tests/tester-create-ts tests/tester-render-ts tests/tester-render-ts-zoneinfo
C_TESTS=tests/c/timelib_get_current_offset_test.cpp tests/c/timelib_decimal_hour.cpp \
	tests/c/timelib_juliandate.cpp tests/c/issues.cpp tests/c/astro_rise_set_altitude.cpp \
	tests/c/parse_date_from_format_test.cpp
TEST_BINARIES=${MANUAL_TESTS} ${AUTO_TESTS}
TARGETDIR=/usr/local
INCLUDEDIR=${TARGETDIR}/include
LIBRARYDIR=${TARGETDIR}/lib

EXAMPLE_BINARIES=docs/date-from-iso-parts docs/date-from-parts docs/date-from-string \
	docs/date-to-parts

all: ${STATIC} ${SHARED}

parse_date.c: timezonemap.h parse_date.re
	re2c -d -b parse_date.re > parse_date.c

parse_iso_intervals.c: parse_iso_intervals.re
	re2c -d -b parse_iso_intervals.re > parse_iso_intervals.c

${STATIC}: ${OBJECTS}
	ar -rc $@ $^
	
${SHARED}: ${OBJECTS}
	${CC} -shared -Wl,-soname,$@ -o $@ $^
	
install:
	cp -f timelib.h ${INCLUDEDIR}
	cp -f ${STATIC} ${SHARED} ${LIBRARYDIR}
	ln -sf ${STATIC} ${LIBRARYDIR}/libtimelib.a
	ln -sf ${SHARED} ${LIBRARYDIR}/libtimelib.so

tests/tester-diff: ${STATIC} tests/tester-diff.c
	$(CC) $(CFLAGS) -o tests/tester-diff tests/tester-diff.c ${STATIC} $(LDFLAGS)

tests/tester-parse-string: ${STATIC} tests/tester-parse-string.c
	$(CC) $(CFLAGS) -o tests/tester-parse-string tests/tester-parse-string.c ${STATIC} $(LDFLAGS)

tests/tester-parse-interval: ${STATIC} tests/tester-parse-interval.c
	$(CC) $(CFLAGS) -o tests/tester-parse-interval tests/tester-parse-interval.c ${STATIC} $(LDFLAGS)

tests/tester-parse-string-by-format: ${STATIC} tests/tester-parse-string-by-format.c
	$(CC) $(CFLAGS) -o tests/tester-parse-string-by-format tests/tester-parse-string-by-format.c ${STATIC} $(LDFLAGS)

tests/tester-create-ts: ${STATIC} tests/tester-create-ts.c
	$(CC) $(CFLAGS) -o tests/tester-create-ts tests/tester-create-ts.c ${STATIC} $(LDFLAGS)

tests/tester-parse-tz: ${STATIC} tests/test-tz-parser.c
	$(CC) $(CFLAGS) -o tests/tester-parse-tz tests/test-tz-parser.c ${STATIC} $(LDFLAGS)

tests/tester-render-ts: ${STATIC} tests/tester-render-ts.c
	$(CC) $(CFLAGS) -o tests/tester-render-ts tests/tester-render-ts.c ${STATIC} $(LDFLAGS)

tests/tester-render-ts-zoneinfo: ${STATIC} tests/tester-render-ts-zoneinfo.c
	$(CC) $(CFLAGS) -o tests/tester-render-ts-zoneinfo tests/tester-render-ts-zoneinfo.c ${STATIC} $(LDFLAGS)

tests/tester-iso-week: ${STATIC} tests/tester-iso-week.c
	$(CC) $(CFLAGS) -o tests/tester-iso-week tests/tester-iso-week.c ${STATIC} $(LDFLAGS)

tests/test-abbr-to-id: ${STATIC} tests/test-abbr-to-id.c
	$(CC) $(CFLAGS) -o tests/test-abbr-to-id tests/test-abbr-to-id.c ${STATIC} $(LDFLAGS)

tests/test-astro: ${STATIC} tests/test-astro.c
	$(CC) $(CFLAGS) -o tests/test-astro tests/test-astro.c ${STATIC} -lm $(LDFLAGS)

tests/enumerate-timezones: ${STATIC} tests/enumerate-timezones.c
	$(CC) $(CFLAGS) -o tests/enumerate-timezones tests/enumerate-timezones.c ${STATIC} $(LDFLAGS)

tests/date_from_isodate: ${STATIC} tests/date_from_isodate.c
	$(CC) $(CFLAGS) -o tests/date_from_isodate tests/date_from_isodate.c ${STATIC} $(LDFLAGS)


docs/date-from-parts: ${STATIC} docs/date-from-parts.c
	$(CC) $(CFLAGS) -o docs/date-from-parts docs/date-from-parts.c ${STATIC} $(LDFLAGS)

docs/date-from-iso-parts: ${STATIC} docs/date-from-iso-parts.c
	$(CC) $(CFLAGS) -o docs/date-from-iso-parts docs/date-from-iso-parts.c ${STATIC} $(LDFLAGS)

docs/date-from-string: ${STATIC} docs/date-from-string.c
	$(CC) $(CFLAGS) -o docs/date-from-string docs/date-from-string.c ${STATIC} $(LDFLAGS)

docs/date-to-parts: ${STATIC} docs/date-to-parts.c
	$(CC) $(CFLAGS) -o docs/date-to-parts docs/date-to-parts.c ${STATIC} $(LDFLAGS)


timezonemap.h: gettzmapping.php
	echo Generating timezone mapping file.
	php gettzmapping.php > timezonemap.h

clean-all: clean
	rm -f timezonemap.h

clean:
	rm -f parse_iso_intervals.c parse_date.c *.o ${STATIC} ${SHARED} ${TEST_BINARIES}

ctest: tests/c/all_tests.cpp timelib.a ${C_TESTS}
	$(CXX) $(CPPFLAGS) $(LDFLAGS) tests/c/all_tests.cpp ${C_TESTS} ${STATIC} $(TEST_LDFLAGS) -o ctest

test: ctest tests/tester-parse-string tests/tester-create-ts tests/tester-render-ts tests/tester-render-ts-zoneinfo tests/tester-parse-string-by-format
	-@php tests/test_all.php
	@echo Running C tests
	@./ctest -c

test-parse-string: tests/tester-parse-string
	@for i in tests/files/*.parse; do echo $$i; php tests/test_parser.php $$i; echo; done

test-parse-format: tests/tester-parse-string-by-format
	@for i in tests/files/*.parseformat; do echo $$i; php tests/test_parse_format.php $$i; echo; done

test-create-ts: tests/tester-create-ts
	@for i in tests/files/*.ts; do echo $$i; php tests/test_create.php $$i; echo; done

test-render-ts: tests/tester-render-ts
	@for i in tests/files/*.render; do echo $$i; php tests/test_render.php $$i; echo; done

test-render-ts-zoneinfo: tests/tester-render-ts-zoneinfo
	@for i in tests/files/*.render; do echo $$i; php tests/test_render.php $$i; echo; done

package: clean
	tar -cvzf parse_date.tar.gz parse_date.re Makefile tests
