/*
 * $Id: list_seealso.cc,v 1.2 2003/05/15 15:32:36 dburke Exp $
 *
 * Usage:
 *   list_seealso seealsogrpup1 ... seealsogroupN
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
 *   CIAO >= 3.0 to have been started
 */

#include "Strings.hh"
#include "AhelpDB.hh"

void PrintSynopsis()
{
  cerr << "Usage: list_seealso seealsogroup1 ... seealsogroupN" << endl;
};

int main(int argc, char **argv)
{
  Strings group;
  StringsList matchList;

  AhelpDB * ahelpDB;

  int argIndx;
  int status = 0;

  if ( argc < 2 ) {
    PrintSynopsis();
    return 1;
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
    StringsListIterator matchIter( &matchList );
    for ( matchIter.First(); !matchIter.IsDone(); matchIter.Next() ) {
      StringsList match = matchIter.GetCurrent().Split();
      cout << group << " " << match.GetFirst() << " " << match.GetLast() << endl;
    } 

  } // for: argIndx

  // finished
  delete ahelpDB;

  exit( 0 );
}

