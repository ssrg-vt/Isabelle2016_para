/*  Title:      Pure/Tools/doc.scala
    Author:     Makarius

View Isabelle documentation.
*/

package isabelle


import scala.util.matching.Regex


object Doc
{
  /* dirs */

  def dirs(): List[Path] =
    Path.split(Isabelle_System.getenv("ISABELLE_DOCS")).map(dir =>
      if (dir.is_dir) dir
      else error("Bad documentation directory: " + dir))
    

  /* contents */

  private def contents_lines(): List[String] =
    for {
      dir <- dirs()
      catalog = dir + Path.basic("Contents")
      if catalog.is_file
      line <- split_lines(Library.trim_line(File.read(catalog)))
    } yield line

  sealed abstract class Entry
  case class Section(text: String) extends Entry
  case class Doc(name: String, title: String) extends Entry
  case class Text_File(path: Path) extends Entry

  private val Section_Entry = new Regex("""^(\S.*)\s*$""")
  private val Doc_Entry = new Regex("""^\s+(\S+)\s+(.+)\s*$""")

  private val release_notes =
    List(Section("Release notes"),
      Text_File(Path.explode("~~/ANNOUNCE")),
      Text_File(Path.explode("~~/README")),
      Text_File(Path.explode("~~/NEWS")),
      Text_File(Path.explode("~~/COPYRIGHT")),
      Text_File(Path.explode("~~/CONTRIBUTORS")))

  def contents(): List[Entry] =
    (for {
      line <- contents_lines()
      entry <-
        line match {
          case Section_Entry(text) => Some(Section(text))
          case Doc_Entry(name, title) => Some(Doc(name, title))
          case _ => None
        }
    } yield entry) ::: release_notes


  /* view */

  def view(name: String)
  {
    val doc = name + "." + Isabelle_System.getenv_strict("ISABELLE_DOC_FORMAT")
    dirs().find(dir => (dir + Path.basic(doc)).is_file) match {
      case Some(dir) =>
        Isabelle_System.bash_env(dir.file, null,
          "\"$ISABELLE_TOOL\" display " + quote(doc) + " >/dev/null 2>/dev/null &")
      case None => error("Missing Isabelle documentation file: " + quote(doc))
    }
  }


  /* command line entry point */

  def main(args: Array[String])
  {
    Command_Line.tool {
      if (args.isEmpty) Console.println(cat_lines(contents_lines()))
      else args.foreach(view)
      0
    }
  }
}

