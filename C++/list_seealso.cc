/*
 * Usage:
 *   list_seealso seealsogroup1 ... seealsogroupN
 *   list_seealso --version
 *
 * Aim:
 *   print to the screen the contents of the given seealso groups
 *   Used by ahelp 2 HTML code, for generating both the
 *   distribution and web site pages
 *
 *   If the seealsogroup isn't found then we silently ignore it
 *   - had previously printed a warning but our ahelp files aren't
 *     all 'correct' and at some level having a value only once
 *     in the seealso section is allowed
 *
 * Requires;
 *   CIAO >= 4.0 to have been started
 */

#include "AhelpStrings.hh"
#include "AhelpDB.hh"

/* found in src/install/ */
#include "cxcds_version.h"

void PrintSynopsis()
{
  cerr << "Usage: list_seealso seealsogroup1 ... seealsogroupN" << endl;
  cerr << "       list_seealso --version" << endl;
};

int main(int argc, char **argv)
{
  AhelpStrings group;
  AhelpStringsList matchList;

  AhelpDB * ahelpDB;

  int argIndx;
  int status = 0;

  if (argc == 1) {
    PrintSynopsis();
    return 1;
  }

  if (0 == strncmp ("--version", argv[1], 9)) {
    cout << "Compiled against: " << CXCDS_VERSION_STRING << endl;
    return 0;
  }

  ahelpDB = new AhelpDB(getenv("ASCDS_INSTALL"));

  // simple command-line handling
  for ( argIndx = 1; argIndx < argc; argIndx++ ) {
    group = argv[argIndx];

    status = ahelpDB->FindSEEALSO( group, matchList );
    if ( status != 1 ) continue;
#ifdef OLDCODE
    if ( status != 1 ) {
      cerr << "Unable to find the 'See Also' group for " << group << "." << endl;
      exit( 1 );
    }
#endif

    // cout << "NOTE: number of matches = " << matchList.GetLength() << endl;

    // do we need this?
    matchList.Sort(TRUE,TRUE);

    // try and parse the list
    AhelpStringsListIterator matchIter( &matchList );
    for ( matchIter.First(); !matchIter.IsDone(); matchIter.Next() ) {
      AhelpStringsList match = matchIter.GetCurrent().Split();
      cout << group << " " << match.GetFirst() << " " << match.GetLast() << endl;
    } 

  } // for: argIndx

  // finished
  delete ahelpDB;

  exit( 0 );
}

