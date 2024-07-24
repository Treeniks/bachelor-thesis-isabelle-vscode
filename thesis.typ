#import "/layout/thesis_template.typ": *
#import "/metadata.typ": *

#set document(title: titleEnglish, author: author)

#show: thesis.with(
  title: titleEnglish,
  titleGerman: titleGerman,
  degree: degree,
  program: program,
  supervisor: supervisor,
  advisors: advisors,
  author: author,
  startDate: startDate,
  submissionDate: submissionDate,
  abstract_en: include "/content/00_abstract_en.typ",
  abstract_de: include "/content/00_abstract_de.typ",
)

#include "/content/01_introduction.typ"
#include "/content/02_background.typ"
#include "/content/03_related_work.typ"
#include "/content/04_main_both.typ"
#include "/content/05_main_server.typ"
#include "/content/06_main_client.typ"
// #include "/content/07_evaluation.typ"
#include "/content/08_summary.typ"
