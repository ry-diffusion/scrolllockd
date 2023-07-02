{
	description = "A keyboard scrollock daemon";

	outputs = { self, nixpkgs }:
	{
		defaultPackage.x86_64-linux = with import nixpkgs { system = "x86_64-linux"; };
		stdenv.mkDerivation {
			name = "scrollockd";
			src = self;
			nativeBuildInputs = [ meson ninja libevdev pkg-config ];
			mesonFlags = [ "-Denable_systemd=false" ] ;
			buildInputs = [ libevdev ];
		};
	};
}
