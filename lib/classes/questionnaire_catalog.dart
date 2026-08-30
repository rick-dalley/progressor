// Progressor doesn't need the actual question sets — only Ally renders those — so
// this is deliberately just id + display name, kept in sync by hand with Ally's own
// (much larger) questionnaire_catalog.dart. `id` is what travels in the
// ally://assignQuestionnaire payload and must match one of Ally's catalog entries
// exactly.
class QuestionnaireCatalogEntry {
  final String id;
  final String name;
  final String description;

  const QuestionnaireCatalogEntry({required this.id, required this.name, required this.description});
}

const List<QuestionnaireCatalogEntry> questionnaireCatalog = [
  QuestionnaireCatalogEntry(id: 'PHQ-9', name: 'PHQ-9', description: 'Depression screening'),
  QuestionnaireCatalogEntry(id: 'GAD-7', name: 'GAD-7', description: 'Anxiety screening'),
  QuestionnaireCatalogEntry(id: 'C-SSRS', name: 'C-SSRS', description: 'Suicide risk screening'),
  QuestionnaireCatalogEntry(id: 'DAST-10', name: 'DAST-10', description: 'Drug abuse screening'),
  QuestionnaireCatalogEntry(id: 'ASRS-V1.1', name: 'ASRS-V1.1', description: 'Adult ADHD screening'),
  QuestionnaireCatalogEntry(id: 'PCL-5', name: 'PCL-5', description: 'PTSD checklist'),
];
