CAGE_CODES = DynList.build_from('IPD_BUSINESSID', :bdesc)

CHANGE_CLASSES = DynList.build_from('IPD_CHNGCLASS', :bdesc)

CHANGE_SUBCLASSES = DynList.build_from('IPD_CHNGSUBCLASS', :bdesc)

CHILDREN = YAML::load(File.open("#{RAILS_ROOT}/config/settings/children.yml"))

DOCUMENT_SIZES = DynList.build_from('IPD_DOCSIZE', :bdesc)

MSG = YAML::load(File.open("#{RAILS_ROOT}/config/settings/messages.yml"))

FORMS = YAML::load(File.open("#{RAILS_ROOT}/config/settings/record_forms.yml"))

NAVIGATION = YAML::load(File.open("#{RAILS_ROOT}/config/settings/navigation.yml"))

PARENTS = YAML::load(File.open("#{RAILS_ROOT}/config/settings/parents.yml"))

PREF = YAML::load(File.open("#{RAILS_ROOT}/config/settings/preferences.yml"))

PROJECT_LIST = Bproject.find(:all).map { |prj| prj.bname }.sort
PROJECT_LIST.unshift('')

USER_LIST = Bdbuser.find(:all).map { |user| user.buser }.sort.uniq
USER_LIST.unshift('')

#################################################################################
# Le costanti sottostanti sono funzione delle precedenti
#################################################################################

APPL_RECTYPES = NAVIGATION['FIND'].map { |nav| nav['type'] } - ['GENERIC']
