# PLEASE REMOVE ALL GENERATED COMMENTS BEFORE SUBMITTING YOUR PULL REQUEST!
class Ccx < Formula
  desc "Three-Dimensional Finite Element Solver"
  homepage "http://www.calculix.de"
  url "http://www.dhondt.de/ccx_2.15.src.tar.bz2"
  sha256 "bc7dba721935af51b60c1b5aa1529a420476fc6432a7bec5254f8dfabaeb8a34"

  #option "with-openmp", "build with OpenMP support"
  #needs :openmp if build.with? "openmp"

  depends_on "gcc" if OS.mac? # for gfortran
  depends_on "arpack"
  depends_on "pkg-config" => :build

  resource "test" do
    url "http://www.dhondt.de/ccx_2.15.test.tar.bz2"
    sha256 "ee17e477aeae944c35853a663ac245c33b405c3750308c5d77e5ee9a4e609dd5"
  end

  resource "doc" do
    url "http://www.dhondt.de/ccx_2.15.htm.tar.bz2"
    sha256 "0bfdef36076d3d1d1b7f8cd1d5a886915f7b0b54ed5ae7a7f71fa813ef655922"
  end

  resource "spooles" do
    # The spooles library is not currently maintained and so would not make a
    # good brew candidate. Instead it will be static linked to ccx.
    url "http://www.netlib.org/linalg/spooles/spooles.2.2.tgz"
    sha256 "a84559a0e987a1e423055ef4fdf3035d55b65bbe4bf915efaa1a35bef7f8c5dd"
  end
  
  patch :DATA

  def install
    (buildpath/"spooles").install resource("spooles")

    # Patch spooles library
    inreplace "spooles/Make.inc", "/usr/lang-4.0/bin/cc", ENV.cc
    inreplace "spooles/Tree/src/makeGlobalLib", "drawTree.c", "tree.c"
    #inreplace "ccx_2.15/src/Makefile", "-fopenmp", "" if build.without? "openmp"

    # Build serial spooles library
    system "make", "-C", "spooles", "lib"

    # Extend library with multi-threading (MT) subroutines
    system "make", "-C", "spooles/MT/src", "makeLib"

    # Buid Calculix ccx
    fflags= %w[-O2]
    fflags << "-fopenmp" if build.with? "openmp"
    cflags = %w[-O2 -I../../spooles -DARCH=Linux -DSPOOLES -DARPACK -DMATRIXSTORAGE]
    #cflags << "-DUSE_MT=1" if build.with? "openmp"
    libs = ["$(DIR)/spooles.a", "$(shell pkg-config --libs arpack)"]
    # ARPACK uses Accelerate on macOS and OpenBLAS on Linux
    libs << "-framework accelerate" if OS.mac?
    #libs << "-lopenblas -pthread" if OS.linux? # OpenBLAS uses pthreads
    args = ["CC=#{ENV.cc}",
            "FC=#{ENV.fc}",
            "CFLAGS=#{cflags.join(" ")}",
            "FFLAGS=#{fflags.join(" ")}",
            "DIR=../../spooles",
            "LIBS=#{libs.join(" ")}"]
    target = Pathname.new("ccx_2.15/src/ccx_2.15")
    system "make", "-C", target.dirname, target.basename, *args
    bin.install target

    (buildpath/"test").install resource("test")
    pkgshare.install Dir["test/ccx_2.15/test/*"]

    (buildpath/"doc").install resource("doc")
    doc.install Dir["doc/ccx_2.15/doc/ccx/*"]
  end

  test do
    cp "#{pkgshare}/spring1.inp", testpath
    system "#{bin}/ccx_2.15", "spring1"
  end
end

__END__
diff --git a/ccx_2.15/src/Makefile b/ccx_2.15/src/Makefile
index 9cab2fc..d1e4827 100755
--- a/ccx_2.15/src/Makefile
+++ b/ccx_2.15/src/Makefile
@@ -25,7 +25,7 @@ LIBS = \
 	../../../ARPACK/libarpack_INTEL.a \
        -lpthread -lm -lc
 
-ccx_2.15: $(OCCXMAIN) ccx_2.15.a  $(LIBS)
+ccx_2.15: $(OCCXMAIN) ccx_2.15.a
 	./date.pl; $(CC) $(CFLAGS) -c ccx_2.15.c; $(FC)  -Wall -O3 -o $@ $(OCCXMAIN) ccx_2.15.a $(LIBS)
 
 ccx_2.15.a: $(OCCXF) $(OCCXC)
