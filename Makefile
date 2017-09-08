build/gz_2010_us_050_00_20m.zip:
	mkdir -p $(dir $@)
	curl -o $@ http://www2.census.gov/geo/tiger/GENZ2015/shp/cb_2015_us_county_20m.zip

build/gz_2010_us_050_00_20m.shp: build/gz_2010_us_050_00_20m.zip
	unzip -od $(dir $@) $<
	touch $@

build/counties.json: build/gz_2010_us_050_00_20m.shp
	node_modules/.bin/topojson \
		-o $@ \
		-p \
		--projection='width = 600, height = 375, d3.geo.albersUsa() \
			.scale(800) \
			.translate([width / 2, height / 2])' \
		--simplify=.5 \
		-- counties=$<

build/counties.json: build/gz_2010_us_050_00_20m.shp build/mock_users.csv
	node_modules/.bin/topojson \
		-o $@ \
		-p \
		--id-property='STATE+COUNTY, STATEFP+COUNTYFP' \
		--external-properties=build/mock_users.csv \
		--properties=STATE \
		--properties=COUNTY \
		--properties='state_name=STNAME' \
		--properties='county_name=COUNAME' \
		--properties='population=+POPULATION' \
		--properties='total_users=+Total_Users' \
		--properties='total_votes=+Total_Votes' \
		--properties='Jan_2011=+Users_2011' \
		--properties='Jan_2012=+Users_2012' \
		--properties='Jan_2013=+Users_2013' \
		--properties='Jan_2014=+Users_2014' \
		--properties='Jan_2015=+Users_2015' \
		--properties='Jan_2016=+Users_2016' \
		--properties='Jan_2017=+Users_2017' \
		--properties='Lon=LONGITUDE' \
		--properties='Lat=LATITUDE' \
		--projection='width = 600, height = 375, d3.geo.albersUsa() \
			.scale(800) \
			.translate([width / 2, height / 2])' \
		--simplify=.5 \
		-- counties=$<

build/states.json: build/counties.json #states_fips.csv
	node_modules/.bin/topojson-merge \
		-o $@ \
		-p \
		--in-object=counties \
		--out-object=states \
		--key='d.id.substring(0,2)' \
		-- $<

	node_modules/.bin/topojson build/states.json \
 		-o build/states_named.json \
	 	-e build/states_fips.csv \
		--id-property=STATE,state_id \
		-p name=state_name,county_name,population,total_users,total_votes,Jan_2011,Jan_2012,Jan_2013,Jan_2014,Jan_2015,Jan_2016,Jan_2017,Lon,Lat \
		-- build/states.json

us.json: build/states_named.json
	node_modules/.bin/topojson-merge \
		-o $@ \
		--in-object=states \
		--out-object=nation \
		-- $<
