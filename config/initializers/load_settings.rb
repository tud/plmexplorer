ALTERNATE_LANGUAGE = [
  [ 'Default',                       '0' ],
  [ 'English Alternate Description', '1' ]
]

CAGE_CODES = DynList.build_from('IPD_BUSINESSID', :bdesc)

CHANGE_CLASSES = DynList.build_from('IPD_CHNGCLASS', :bdesc)

CHANGE_SUBCLASSES = DynList.build_from('IPD_CHNGSUBCLASS', :bdesc)

CHILDREN = YAML::load(File.open("#{RAILS_ROOT}/config/settings/children.yml"))

DATA_MATURITY = [
  'CURRENT',
  'RELEASED'
]

DOCUMENT_SIZES = DynList.build_from('IPD_DOCSIZE', :bdesc)

LOGISTIC_ITEMS = [
  [ 'Ricambio',              'R'  ],
  [ 'Dotazione',             'D'  ],
  [ 'Dotazione-Ricambio',    'DR' ],
  [ 'Attrezzatura',          'A'  ],
  [ 'Attrezzatura-Ricambio', 'AR' ]
]

MSG = YAML::load(File.open("#{RAILS_ROOT}/config/settings/messages.yml"))

FORMS = YAML::load(File.open("#{RAILS_ROOT}/config/settings/record_forms.yml"))

NAVIGATION = YAML::load(File.open("#{RAILS_ROOT}/config/settings/navigation.yml"))

ODM_TYPE = [
  'CHANGE',
  'CHANGE_LOG'
]

PARENTS = YAML::load(File.open("#{RAILS_ROOT}/config/settings/parents.yml"))

PREF = YAML::load(File.open("#{RAILS_ROOT}/config/settings/preferences.yml"))

PRINTERS = DynList.build_from('IPD_PRINTER', :bdesc)

PROJECT_LIST = Bproject.find(:all).map { |prj| prj.bname }.sort

RECORD_TYPE = [
  [ 'Part/Document', '0' ],
  [ 'Part',          '1' ]
]

REPORT_FORMAT = [
  'COMPLETO',
  'LISTA'
]

USER_LIST = Bdbuser.find(:all).map { |user| user.buser }.sort.uniq

WA_STATUS = [
  'CLOSED',
  'COMPLETE',
  'CREATED',
  'REJECTED'
]

WA_TYPE = [
  'CHANGE',
  'CHANGE_LOG',
  'TASK',
  'TASK_LOG'
]

YES_NO = [
  [ 'YES', 'Y' ],
  [ 'NO',  'N' ]
]

#################################################################################
# Le costanti sottostanti sono funzione delle precedenti
#################################################################################

APPL_RECTYPES = NAVIGATION['FIND'].map { |nav| nav['type'] } - ['GENERIC']
