class InventoryLoan < ActiveRecord::Base
  include InventoryObjectTokenInputtable
  include LoaneeTokenInputtable

  attr_accessible :loaned_date, :returned_date, :loanee_id, :inventory_object_id, 
                  :loanee_name, :inventory_object_name
  
  belongs_to :inventory_object
  belongs_to :loanee
  
  has_many :audit_log_entries, as: :auditable
  
  validates_associated :inventory_object
  validates_presence_of :inventory_object_id
  validates_associated :loanee
  validates_presence_of :loanee_id
  validates :loaned_date, :presence => :true
  validate :only_current_loan, :on => :create
  
  scope :open, -> {where("inventory_loans.returned_date IS NOT NULL") }
  
  #default values
  after_initialize :init
  
  after_create do
	audit_log = audit_log_entries.new
	audit_log.administrator = Administrator.current
	audit_log.desc = "%a created %o at #{self.created_at}"
	audit_log.save
  end
  
  around_update :around_update_audit
  def around_update_audit 
	changed = self.changed
	yield
	if changed.include? "returned_date" then
		self.audit_log_entries.create(administrator_id: Administrator.current.id, desc: "%a closed %o at #{self.returned_date}")
	end
  end
  
  #audit_name
  def audit_name
	"#{inventory_object_name} to #{loanee_name}"
  end
  
  #name accessors/getters
  def inventory_object_name=(name)
    object = InventoryObject.new.search(name)
    self.inventory_object = object unless object.respond_to?('count')
  end

  def inventory_object_name
    self.inventory_object.nil? ? "" : self.inventory_object.id1 
  end
  
  def loanee_name=(name)
    loanee_res = Loanee.new.search(name)
    logger.debug loanee_res
    self.loanee = loanee_res unless loanee_res.respond_to?('count')
  end
  
  def loanee_name
    self.loanee.nil? ? "" : self.loanee.fullname
  end
  #is this loan current?
  def current?
    returned_date.nil?
  end
  
  comma do
    inventory_object_name "Inventory Object"
    loanee_name "Loanee"
  end
  
  private
  #validates that there is only one current loan for each inventory_object
  def only_current_loan
    #if the attached object has another other current loans give an error
    if inventory_object &&
       (inventory_object.inventory_loans.select {|loan| loan.current? && loan != self}).count != 0 then
      errors.add(:inventory_object, "An Inventory Object may only be loaned to one Loanee at a time!")
    end
  end
  
  def init
	self.loaned_date ||= Date.today
  end
end
