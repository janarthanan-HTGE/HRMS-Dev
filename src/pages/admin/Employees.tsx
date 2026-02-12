import { useEffect, useState } from 'react';
import { supabase } from '@/integrations/supabase/client';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardHeader } from '@/components/ui/card';
import { Input } from '@/components/ui/input';
import { Table, TableBody, TableCell, TableHead, TableHeader, TableRow } from '@/components/ui/table';
import { Badge } from '@/components/ui/badge';
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from '@/components/ui/dialog';
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from '@/components/ui/form';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { AlertDialog, AlertDialogAction, AlertDialogCancel, AlertDialogContent, AlertDialogDescription, AlertDialogFooter, AlertDialogHeader, AlertDialogTitle, AlertDialogTrigger } from '@/components/ui/alert-dialog';
import { useToast } from '@/hooks/use-toast';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Plus, Pencil, Trash2, UserX, Search, Eye, EyeOff } from 'lucide-react';
import { useAuth } from '@/contexts/AuthContext';

const employeeSchema = z.object({
  email: z.string().email('Invalid email'),
  password: z.string().min(6, 'Min 6 characters').optional(),
  first_name: z.string().min(1, 'Required'),
  last_name: z.string().min(1, 'Required'),
  phone: z.string().optional(),
  role: z.enum(['hr', 'employee'] as const),
  department_id: z.string().optional(),
  designation_id: z.string().optional(),
  date_of_birth: z.string().optional(),
  joining_date: z.string().optional(),
  employee_id: z.string().min(1, 'Required'),
  reporting_manager: z.string().optional(),
});

type EmployeeFormData = z.infer<typeof employeeSchema>;

interface Employee {
  id: string;
  email: string;
  first_name: string;
  last_name: string;
  phone: string | null;
  role: string;
  employee_id: string | null;
  department_id: string | null;
  designation_id: string | null;
  date_of_birth: string | null;
  joining_date: string | null;
  reporting_manager: string | null;
  employment_status: string | null;
}

export default function Employees() {
  const { user } = useAuth();
  const [employees, setEmployees] = useState<Employee[]>([]);
  const [departments, setDepartments] = useState<{ id: string; name: string }[]>([]);
  const [designations, setDesignations] = useState<{ id: string; name: string }[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [dialogOpen, setDialogOpen] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [showPassword, setShowPassword] = useState(false);
  const { toast } = useToast();

  const isHR = user?.role === 'hr';

  const form = useForm<EmployeeFormData>({
    resolver: zodResolver(employeeSchema),
    defaultValues: {
      email: '', password: '', first_name: '', last_name: '', phone: '',
      role: 'employee', department_id: '', designation_id: '',
      date_of_birth: '', joining_date: '', employee_id: '', reporting_manager: '',
    },
  });

  const fetchData = async () => {
    try {
      const [empRes, deptRes, desigRes] = await Promise.all([
        supabase.from('app_users_public').select('*').neq('role', 'admin').order('created_at', { ascending: false }),
        supabase.from('departments').select('*'),
        supabase.from('designations').select('*'),
      ]);
      setEmployees((empRes.data || []) as Employee[]);
      setDepartments(deptRes.data || []);
      setDesignations(desigRes.data || []);
    } catch (e) {
      console.error(e);
    } finally {
      setLoading(false);
    }
  };

  useEffect(() => { fetchData(); }, []);

  const onSubmit = async (data: EmployeeFormData) => {
    try {
      if (editingId) {
        const { error } = await supabase
          .from('app_users')
          .update({
            first_name: data.first_name,
            last_name: data.last_name,
            phone: data.phone || null,
            department_id: data.department_id || null,
            designation_id: data.designation_id || null,
            date_of_birth: data.date_of_birth || null,
            joining_date: data.joining_date || null,
            employee_id: data.employee_id || null,
            reporting_manager: data.reporting_manager || null,
          })
          .eq('id', editingId);
        if (error) throw error;
        toast({ title: 'Employee updated successfully' });
      } else {
        if (!data.password) {
          toast({ title: 'Error', description: 'Password required for new employees', variant: 'destructive' });
          return;
        }
        if (isHR && data.role !== 'employee') {
          toast({ title: 'Error', description: 'HR can only create employees', variant: 'destructive' });
          return;
        }

        const { data: result, error } = await supabase.rpc('create_app_user', {
          p_email: data.email,
          p_password: data.password,
          p_first_name: data.first_name,
          p_last_name: data.last_name,
          p_role: data.role,
          p_phone: data.phone || null,
          p_employee_id: data.employee_id || null,
          p_department_id: data.department_id || null,
          p_designation_id: data.designation_id || null,
          p_date_of_birth: data.date_of_birth || null,
          p_joining_date: data.joining_date || null,
          p_reporting_manager: data.reporting_manager || null,
        });
        if (error) throw error;
        const res = result as any;
        if (!res.success) throw new Error(res.error);
        toast({ title: 'Employee created successfully' });
      }
      closeDialog();
      fetchData();
    } catch (e: any) {
      toast({ title: 'Error', description: e.message, variant: 'destructive' });
    }
  };

  const handleEdit = (emp: Employee) => {
    setEditingId(emp.id);
    form.reset({
      email: emp.email || '',
      password: '',
      first_name: emp.first_name || '',
      last_name: emp.last_name || '',
      phone: emp.phone || '',
      role: (emp.role as 'hr' | 'employee') || 'employee',
      department_id: emp.department_id || '',
      designation_id: emp.designation_id || '',
      date_of_birth: emp.date_of_birth || '',
      joining_date: emp.joining_date || '',
      employee_id: emp.employee_id || '',
      reporting_manager: emp.reporting_manager || '',
    });
    setDialogOpen(true);
  };

  const handleFire = async (emp: Employee) => {
    const { error } = await supabase.from('app_users').update({ employment_status: 'fired' }).eq('id', emp.id);
    if (error) { toast({ title: 'Error', description: error.message, variant: 'destructive' }); return; }
    toast({ title: `${emp.first_name} ${emp.last_name} marked as fired` });
    fetchData();
  };

  const handleDelete = async (emp: Employee) => {
    const { error } = await supabase.from('app_users').delete().eq('id', emp.id);
    if (error) { toast({ title: 'Error', description: error.message, variant: 'destructive' }); return; }
    toast({ title: `${emp.first_name} ${emp.last_name} deleted` });
    fetchData();
  };

  const closeDialog = () => {
    setDialogOpen(false);
    setEditingId(null);
    form.reset();
    setShowPassword(false);
  };

  const filtered = employees.filter(e =>
    `${e.first_name} ${e.last_name} ${e.email}`.toLowerCase().includes(search.toLowerCase())
  );

  const deptName = (id: string | null) => departments.find(d => d.id === id)?.name || '-';
  const desigName = (id: string | null) => designations.find(d => d.id === id)?.name || '-';

  const statusBadge = (status: string | null) => {
    switch (status) {
      case 'active': return <Badge className="bg-success/10 text-success border-success/20">Active</Badge>;
      case 'fired': return <Badge variant="destructive">Fired</Badge>;
      case 'resigned': return <Badge variant="secondary">Resigned</Badge>;
      default: return <Badge variant="outline">{status}</Badge>;
    }
  };

  if (loading) {
    return (
      <div className="flex items-center justify-center py-12">
        <div className="h-8 w-8 animate-spin rounded-full border-4 border-primary border-t-transparent" />
      </div>
    );
  }

  return (
    <div className="space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold">Employees</h1>
          <p className="text-muted-foreground">Manage all employees and HR personnel</p>
        </div>
        <Dialog open={dialogOpen} onOpenChange={(o) => !o ? closeDialog() : setDialogOpen(true)}>
          <DialogTrigger asChild>
            <Button onClick={() => { setEditingId(null); form.reset(); }}>
              <Plus className="mr-2 h-4 w-4" /> Add Employee
            </Button>
          </DialogTrigger>
          <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-[500px]">
            <DialogHeader>
              <DialogTitle>{editingId ? 'Edit Employee' : 'Add New Employee'}</DialogTitle>
            </DialogHeader>
            <Form {...form}>
              <form onSubmit={form.handleSubmit(onSubmit)} className="space-y-4">
                <div className="grid grid-cols-2 gap-4">
                  <FormField control={form.control} name="first_name" render={({ field }) => (
                    <FormItem><FormLabel>First Name</FormLabel><FormControl><Input {...field} /></FormControl><FormMessage /></FormItem>
                  )} />
                  <FormField control={form.control} name="last_name" render={({ field }) => (
                    <FormItem><FormLabel>Last Name</FormLabel><FormControl><Input {...field} /></FormControl><FormMessage /></FormItem>
                  )} />
                </div>

                <FormField control={form.control} name="email" render={({ field }) => (
                  <FormItem><FormLabel>Email</FormLabel><FormControl><Input type="email" {...field} disabled={!!editingId} /></FormControl><FormMessage /></FormItem>
                )} />

                {!editingId && (
                  <FormField control={form.control} name="password" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Password</FormLabel>
                      <FormControl>
                        <div className="relative">
                          <Input type={showPassword ? 'text' : 'password'} {...field} />
                          <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute right-3 top-1/2 -translate-y-1/2 text-muted-foreground" tabIndex={-1}>
                            {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                          </button>
                        </div>
                      </FormControl>
                      <FormMessage />
                    </FormItem>
                  )} />
                )}

                <FormField control={form.control} name="role" render={({ field }) => (
                  <FormItem>
                    <FormLabel>Role</FormLabel>
                    <Select onValueChange={field.onChange} value={field.value} disabled={!!editingId}>
                      <FormControl><SelectTrigger><SelectValue /></SelectTrigger></FormControl>
                      <SelectContent>
                        <SelectItem value="employee">Employee</SelectItem>
                        {!isHR && <SelectItem value="hr">HR</SelectItem>}
                      </SelectContent>
                    </Select>
                    <FormMessage />
                  </FormItem>
                )} />

                <FormField control={form.control} name="phone" render={({ field }) => (
                  <FormItem><FormLabel>Phone</FormLabel><FormControl><Input {...field} /></FormControl><FormMessage /></FormItem>
                )} />

                <div className="grid grid-cols-2 gap-4">
                  <FormField control={form.control} name="department_id" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Department</FormLabel>
                      <Select onValueChange={field.onChange} value={field.value}>
                        <FormControl><SelectTrigger><SelectValue placeholder="Select" /></SelectTrigger></FormControl>
                        <SelectContent>{departments.map(d => <SelectItem key={d.id} value={d.id}>{d.name}</SelectItem>)}</SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )} />
                  <FormField control={form.control} name="designation_id" render={({ field }) => (
                    <FormItem>
                      <FormLabel>Designation</FormLabel>
                      <Select onValueChange={field.onChange} value={field.value}>
                        <FormControl><SelectTrigger><SelectValue placeholder="Select" /></SelectTrigger></FormControl>
                        <SelectContent>{designations.map(d => <SelectItem key={d.id} value={d.id}>{d.name}</SelectItem>)}</SelectContent>
                      </Select>
                      <FormMessage />
                    </FormItem>
                  )} />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <FormField control={form.control} name="employee_id" render={({ field }) => (
                    <FormItem><FormLabel>Employee ID *</FormLabel><FormControl><Input {...field} placeholder="e.g., EMP001" /></FormControl><FormMessage /></FormItem>
                  )} />
                  <FormField control={form.control} name="reporting_manager" render={({ field }) => (
                    <FormItem><FormLabel>Reporting Manager</FormLabel><FormControl><Input {...field} /></FormControl><FormMessage /></FormItem>
                  )} />
                </div>

                <div className="grid grid-cols-2 gap-4">
                  <FormField control={form.control} name="date_of_birth" render={({ field }) => (
                    <FormItem><FormLabel>Date of Birth</FormLabel><FormControl><Input type="date" {...field} /></FormControl><FormMessage /></FormItem>
                  )} />
                  <FormField control={form.control} name="joining_date" render={({ field }) => (
                    <FormItem><FormLabel>Joining Date</FormLabel><FormControl><Input type="date" {...field} /></FormControl><FormMessage /></FormItem>
                  )} />
                </div>

                <div className="flex justify-end gap-2">
                  <Button type="button" variant="outline" onClick={closeDialog}>Cancel</Button>
                  <Button type="submit">{editingId ? 'Update' : 'Create'}</Button>
                </div>
              </form>
            </Form>
          </DialogContent>
        </Dialog>
      </div>

      <Card>
        <CardHeader>
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input placeholder="Search employees..." value={search} onChange={(e) => setSearch(e.target.value)} className="pl-10" />
          </div>
        </CardHeader>
        <CardContent>
          <Table>
            <TableHeader>
              <TableRow>
                <TableHead>Name</TableHead>
                <TableHead>Email</TableHead>
                <TableHead>Role</TableHead>
                <TableHead>Department</TableHead>
                <TableHead>Designation</TableHead>
                <TableHead>Status</TableHead>
                <TableHead className="text-right">Actions</TableHead>
              </TableRow>
            </TableHeader>
            <TableBody>
              {filtered.map((emp) => (
                <TableRow key={emp.id}>
                  <TableCell className="font-medium">{emp.first_name} {emp.last_name}</TableCell>
                  <TableCell>{emp.email}</TableCell>
                  <TableCell><Badge variant={emp.role === 'hr' ? 'default' : 'secondary'}>{emp.role?.toUpperCase()}</Badge></TableCell>
                  <TableCell>{deptName(emp.department_id)}</TableCell>
                  <TableCell>{desigName(emp.designation_id)}</TableCell>
                  <TableCell>{statusBadge(emp.employment_status)}</TableCell>
                  <TableCell className="text-right">
                    <div className="flex justify-end gap-1">
                      <Button size="icon" variant="ghost" onClick={() => handleEdit(emp)}><Pencil className="h-4 w-4" /></Button>
                      <AlertDialog>
                        <AlertDialogTrigger asChild><Button size="icon" variant="ghost" className="text-warning"><UserX className="h-4 w-4" /></Button></AlertDialogTrigger>
                        <AlertDialogContent>
                          <AlertDialogHeader><AlertDialogTitle>Fire {emp.first_name}?</AlertDialogTitle>
                          <AlertDialogDescription>This will mark them as fired.</AlertDialogDescription></AlertDialogHeader>
                          <AlertDialogFooter><AlertDialogCancel>Cancel</AlertDialogCancel><AlertDialogAction onClick={() => handleFire(emp)}>Confirm</AlertDialogAction></AlertDialogFooter>
                        </AlertDialogContent>
                      </AlertDialog>
                      <AlertDialog>
                        <AlertDialogTrigger asChild><Button size="icon" variant="ghost" className="text-destructive"><Trash2 className="h-4 w-4" /></Button></AlertDialogTrigger>
                        <AlertDialogContent>
                          <AlertDialogHeader><AlertDialogTitle>Delete {emp.first_name}?</AlertDialogTitle>
                          <AlertDialogDescription>This action cannot be undone.</AlertDialogDescription></AlertDialogHeader>
                          <AlertDialogFooter><AlertDialogCancel>Cancel</AlertDialogCancel><AlertDialogAction onClick={() => handleDelete(emp)} className="bg-destructive text-destructive-foreground">Delete</AlertDialogAction></AlertDialogFooter>
                        </AlertDialogContent>
                      </AlertDialog>
                    </div>
                  </TableCell>
                </TableRow>
              ))}
              {filtered.length === 0 && (
                <TableRow><TableCell colSpan={7} className="text-center text-muted-foreground py-8">No employees found</TableCell></TableRow>
              )}
            </TableBody>
          </Table>
        </CardContent>
      </Card>
    </div>
  );
}